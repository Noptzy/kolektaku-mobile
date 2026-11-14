import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/settings/settings_logic.dart';
import 'package:kolektaku/features/settings/settings_page_screen.dart';
import 'package:kolektaku/features/settings/settings_pages.dart';
import 'package:kolektaku/features/update/update_host.dart';
import 'package:kolektaku/features/update/update_providers.dart';

import '../../support/fake_update.dart';
import '../../support/screen_harness.dart';

class Rig {
  Rig({this.auto = false, FakeUpdateGateway? gateway})
    : gateway = gateway ?? FakeUpdateGateway();

  final bool auto;
  final FakeUpdateGateway gateway;
  final FakeApkInstaller installer = FakeApkInstaller();
  final ScreenHarness harness = ScreenHarness();

  List<Override> get overrides => [
    autoDownloadProvider.overrideWithValue(auto),
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
