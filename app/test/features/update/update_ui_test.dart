import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/settings/settings_logic.dart';
import 'package:kolektaku/features/settings/settings_page_screen.dart';
import 'package:kolektaku/features/settings/settings_pages.dart';
import 'package:kolektaku/features/update/update_host.dart';
import 'package:kolektaku/features/update/update_labels.dart';
import 'package:kolektaku/features/update/update_providers.dart';
import 'package:kolektaku/features/update/update_state.dart';

import '../../support/fake_update.dart';
import '../../support/screen_harness.dart';

class Rig {
  final FakeUpdateGateway gateway = FakeUpdateGateway();
  final FakeApkInstaller installer = FakeApkInstaller();
  final ScreenHarness harness = ScreenHarness();

  List<Override> get overrides => [
    updateGatewayProvider.overrideWithValue(gateway),
    apkInstallerProvider.overrideWithValue(installer),
    appVersionProvider.overrideWith((ref) async => '2.0.0'),
    nowSecondsProvider.overrideWithValue(() => 1_000_000),
    updateFolderProvider.overrideWithValue(() async => '/cache'),
  ];

  Future<void> host(WidgetTester tester) async {
    await harness.pump(
      tester,
      const UpdateHost(child: Text('isi aplikasi')),
      extra: overrides,
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
  }

  Future<void> page(WidgetTester tester) async {
    await harness.pump(
      tester,
      const SettingsPageScreen(page: SettingsPage.update),
      extra: overrides,
    );
  }
}

void main() {
  group('launch', () {
    testWidgets('no update leaves the app alone', (tester) async {
      final rig = Rig();
      await rig.host(tester);
      expect(find.text('isi aplikasi'), findsOneWidget);
      expect(find.byKey(const Key('update-status')), findsNothing);
      expect(find.byKey(const Key('required-update')), findsNothing);
    });

    testWidgets('an update opens a sheet with the notes and a download', (
      tester,
    ) async {
      final rig = Rig();
      rig.gateway.offer = offerOf(
        version: '2.1.0',
        notes: 'Pemutar lebih lancar.',
      );
      await rig.host(tester);
      expect(find.text('Pembaruan 2.1.0'), findsOneWidget);
      expect(find.text('Pemutar lebih lancar.'), findsOneWidget);
      expect(find.byKey(const Key('update-download')), findsOneWidget);
      expect(find.text('Unduh · 4,0 MB'), findsOneWidget);
    });

    testWidgets('later closes the sheet and the app stays usable', (
      tester,
    ) async {
      final rig = Rig();
      rig.gateway.offer = offerOf();
      await rig.host(tester);
      await tester.tap(find.byKey(const Key('update-later')));
      await tester.pumpAndSettle();
      expect(find.text('Pembaruan 2.1.0'), findsNothing);
      expect(find.text('isi aplikasi'), findsOneWidget);
      expect(rig.gateway.downloads, isEmpty);
    });

    testWidgets('a failing check on launch says nothing', (tester) async {
      final rig = Rig();
      rig.gateway.checkError = StateError('offline');
      await rig.host(tester);
      expect(find.text('isi aplikasi'), findsOneWidget);
      expect(find.byKey(const Key('update-status')), findsNothing);
    });

    testWidgets('too soon after the last check nothing happens', (
      tester,
    ) async {
      final rig = Rig();
      rig.gateway.dueResult = false;
      rig.gateway.offer = offerOf();
      await rig.host(tester);
      expect(rig.gateway.checks, isEmpty);
      expect(find.text('Pembaruan 2.1.0'), findsNothing);
    });
  });

  group('required update', () {
    testWidgets('blocks the app until it is updated', (tester) async {
      final rig = Rig();
      rig.gateway.offer = offerOf(required: true);
      await rig.host(tester);
      expect(find.byKey(const Key('required-update')), findsOneWidget);
      expect(find.text('Perlu diperbarui'), findsOneWidget);
      expect(find.byKey(const Key('update-download')), findsOneWidget);
      expect(find.byKey(const Key('update-later')), findsNothing);
    });

    testWidgets('the gate walks through download and install', (tester) async {
      final rig = Rig();
      rig.gateway.offer = offerOf(required: true);
      rig.gateway.events = [progressOf(4, 4, path: '/cache/k.apk')];
      await rig.host(tester);
      await tester.tap(find.byKey(const Key('update-download')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('update-install')), findsOneWidget);
      await tester.tap(find.byKey(const Key('update-install')));
      await tester.pumpAndSettle();
      expect(rig.installer.installed, ['/cache/k.apk']);
    });
  });

  group('settings page', () {
    testWidgets('starts with a check button and the 12 hour note', (
      tester,
    ) async {
      final rig = Rig();
      await rig.page(tester);
      expect(find.byKey(const Key('update-check')), findsOneWidget);
      expect(find.textContaining('12 jam'), findsWidgets);
    });

    testWidgets('a manual check with nothing new says so', (tester) async {
      final rig = Rig();
      await rig.page(tester);
      await tester.tap(find.byKey(const Key('update-check')));
      await tester.pumpAndSettle();
      expect(find.text('Kolektaku sudah versi terbaru.'), findsOneWidget);
    });

    testWidgets('a manual check that fails shows a calm message', (
      tester,
    ) async {
      final rig = Rig();
      rig.gateway.checkError = StateError('offline');
      await rig.page(tester);
      await tester.tap(find.byKey(const Key('update-check')));
      await tester.pumpAndSettle();
      expect(find.textContaining('belum berhasil'), findsOneWidget);
      expect(find.textContaining('offline'), findsNothing);
      expect(find.byKey(const Key('update-check')), findsOneWidget);
    });

    testWidgets('an offer shows its notes and then the retry after a break', (
      tester,
    ) async {
      final rig = Rig();
      rig.gateway.offer = offerOf(notes: 'Banyak perbaikan.');
      rig.gateway.events = [progressOf(1, 4)];
      rig.gateway.downloadError = StateError('cut');
      await rig.page(tester);
      await tester.tap(find.byKey(const Key('update-check')));
      await tester.pumpAndSettle();
      expect(find.text('Versi 2.1.0 tersedia.'), findsOneWidget);
      expect(find.text('Banyak perbaikan.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('update-download')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('update-retry')), findsOneWidget);
      expect(find.textContaining('belum berhasil'), findsOneWidget);
    });
  });

  group('labels', () {
    test('sizes and percentages read naturally', () {
      expect(megabytes(1536 * 1024), '1,5 MB');
      expect(percentLabel(0.456), '46%');
      expect(percentLabel(null), '');
    });

    test('the summary follows the state', () {
      expect(
        updateSummary(const UpdateState(), '2.0.0'),
        'Versi 2.0.0 · cek versi baru',
      );
      expect(updateSummary(const UpdateState(), null), 'Cek versi baru');
      expect(
        updateSummary(const UpdateState(phase: UpdatePhase.upToDate), '2.0.0'),
        'Sudah versi terbaru',
      );
      expect(
        updateSummary(const UpdateState(phase: UpdatePhase.checking), '2.0.0'),
        'Memeriksa…',
      );
    });
  });
}
