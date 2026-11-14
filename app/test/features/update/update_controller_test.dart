import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/app_scope.dart';
import 'package:kolektaku/data/providers/gateway_providers.dart';
import 'package:kolektaku/features/settings/settings_logic.dart';
import 'package:kolektaku/features/update/update_controller.dart';
import 'package:kolektaku/features/update/update_providers.dart';
import 'package:kolektaku/features/update/update_state.dart';
import 'package:kolektaku/platform/apk_installer.dart';

import '../../support/fake_library_gateway.dart';
import '../../support/fake_update.dart';

class Rig {
  Rig() {
    container = ProviderContainer(
      retry: noRetry,
      overrides: [
        updateGatewayProvider.overrideWithValue(gateway),
        apkInstallerProvider.overrideWithValue(installer),
        libraryGatewayProvider.overrideWithValue(library),
        appVersionProvider.overrideWith((ref) async => '2.0.0'),
        nowSecondsProvider.overrideWithValue(() => now),
        updateFolderProvider.overrideWithValue(() async => '/cache'),
      ],
    );
    addTearDown(container.dispose);
    container.listen(updateControllerProvider, (previous, next) {});
  }

  final FakeUpdateGateway gateway = FakeUpdateGateway();
  final FakeApkInstaller installer = FakeApkInstaller();
  final FakeLibraryGateway library = FakeLibraryGateway();
  int now = 1_000_000;
  late final ProviderContainer container;

  UpdateController get controller =>
      container.read(updateControllerProvider.notifier);

  UpdateState get state => container.read(updateControllerProvider);
}

void main() {
  group('checking', () {
    test('a manual check sends the version and the phone abis', () async {
      final rig = Rig();
      await rig.controller.checkNow();
      expect(rig.gateway.checks.single.$1, '2.0.0');
      expect(rig.gateway.checks.single.$2, ['arm64-v8a', 'armeabi-v7a']);
      expect(rig.state.phase, UpdatePhase.upToDate);
    });

    test('a newer version is offered with its notes', () async {
      final rig = Rig();
      rig.gateway.offer = offerOf(version: '2.1.0');
      await rig.controller.checkNow();
      expect(rig.state.phase, UpdatePhase.available);
      expect(rig.state.offer!.version, '2.1.0');
      expect(rig.state.total, 4 * 1024 * 1024);
      expect(rig.state.isRequired, isFalse);
    });

    test('a required update says so', () async {
      final rig = Rig();
      rig.gateway.offer = offerOf(required: true);
      await rig.controller.checkNow();
      expect(rig.state.isRequired, isTrue);
    });

    test('the moment of the check is remembered', () async {
      final rig = Rig();
      await rig.controller.checkNow();
      expect(rig.library.prefs[lastCheckKey], '${rig.now}');
    });

    test('a failed manual check is shown without the raw error', () async {
      final rig = Rig();
      rig.gateway.checkError = StateError('offline');
      await rig.controller.checkNow();
      expect(rig.state.phase, UpdatePhase.failed);
      expect(rig.state.offer, isNull);
    });

    test('a second check while one runs does nothing', () async {
      final rig = Rig();
      final first = rig.controller.checkNow();
      await rig.controller.checkNow();
      await first;
      expect(rig.gateway.checks.length, 1);
    });
  });

  group('on launch', () {
    test('asks the 12 hour rule and stays quiet when it is too soon', () async {
      final rig = Rig();
      rig.gateway.dueResult = false;
      rig.library.prefs[lastCheckKey] = '999000';
      await rig.controller.checkOnLaunch();
      expect(rig.gateway.dueAsks.single.last, 999000);
      expect(rig.gateway.dueAsks.single.manual, isFalse);
      expect(rig.gateway.checks, isEmpty);
      expect(rig.state.phase, UpdatePhase.idle);
    });

    test('checks when the rule says it is due', () async {
      final rig = Rig();
      rig.gateway.offer = offerOf();
      await rig.controller.checkOnLaunch();
      expect(rig.gateway.dueAsks.single.last, isNull);
      expect(rig.state.phase, UpdatePhase.available);
    });

    test('a failure on launch never disturbs the user', () async {
      final rig = Rig();
      rig.gateway.checkError = StateError('offline');
      await rig.controller.checkOnLaunch();
      expect(rig.state.phase, UpdatePhase.idle);
      expect(rig.state.error, isNull);
    });

    test('does not ask again once an offer is waiting', () async {
      final rig = Rig();
      rig.gateway.offer = offerOf();
      await rig.controller.checkOnLaunch();
      await rig.controller.checkOnLaunch();
      expect(rig.gateway.checks.length, 1);
    });
  });

  group('downloading and installing', () {
    Future<Rig> offered() async {
      final rig = Rig();
      rig.gateway.offer = offerOf();
      await rig.controller.checkNow();
      return rig;
    }

    test('progress is followed until the file is ready', () async {
      final rig = await offered();
      rig.gateway.events = [
        progressOf(1, 4),
        progressOf(2, 4),
        progressOf(4, 4, path: '/cache/k.apk'),
      ];
      await rig.controller.download();
      expect(rig.gateway.downloads.single, '/cache');
      expect(rig.state.phase, UpdatePhase.ready);
      expect(rig.state.path, '/cache/k.apk');
      expect(rig.state.fraction, 1);
    });

    test('the fraction grows with the bytes received', () async {
      final rig = await offered();
      final seen = <double?>[];
      rig.container.listen(updateControllerProvider, (previous, next) {
        if (next.phase == UpdatePhase.downloading) seen.add(next.fraction);
      });
      rig.gateway.events = [
        progressOf(1, 4),
        progressOf(3, 4),
        progressOf(4, 4, path: '/cache/k.apk'),
      ];
      await rig.controller.download();
      expect(seen, [0.0, 0.25, 0.75]);
    });

    test('a download that breaks keeps the offer for another try', () async {
      final rig = await offered();
      rig.gateway.events = [progressOf(1, 4)];
      rig.gateway.downloadError = StateError('cut');
      await rig.controller.download();
      expect(rig.state.phase, UpdatePhase.failed);
      expect(rig.state.offer, isNotNull);
      rig.gateway.downloadError = null;
      rig.gateway.events = [progressOf(4, 4, path: '/cache/k.apk')];
      await rig.controller.download();
      expect(rig.state.phase, UpdatePhase.ready);
    });

    test('a download that ends without a file is a failure', () async {
      final rig = await offered();
      rig.gateway.events = [progressOf(1, 4)];
      await rig.controller.download();
      expect(rig.state.phase, UpdatePhase.failed);
    });

    test('the finished file is handed to the installer', () async {
      final rig = await offered();
      rig.gateway.events = [progressOf(4, 4, path: '/cache/k.apk')];
      await rig.controller.download();
      await rig.controller.install();
      expect(rig.installer.installed, ['/cache/k.apk']);
    });

    test('an install that fails can be retried without downloading', () async {
      final rig = await offered();
      rig.gateway.events = [progressOf(4, 4, path: '/cache/k.apk')];
      await rig.controller.download();
      rig.installer.installError = const InstallFailure('ditolak');
      await rig.controller.install();
      expect(rig.state.phase, UpdatePhase.failed);
      expect(rig.state.path, '/cache/k.apk');
      rig.installer.installError = null;
      await rig.controller.install();
      expect(rig.installer.installed, ['/cache/k.apk']);
      expect(rig.gateway.downloads.length, 1);
    });

    test('nothing downloads or installs without an offer or a file', () async {
      final rig = Rig();
      await rig.controller.download();
      await rig.controller.install();
      expect(rig.gateway.downloads, isEmpty);
      expect(rig.installer.installed, isEmpty);
    });
  });
}
