import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/update/update_controller.dart';
import 'package:kolektaku/features/update/update_state.dart';

import '../../support/fake_update.dart';
import 'update_controller_test.dart' show Rig;

Rig readyToFetch({bool required = false, bool offer = true}) {
  final rig = Rig(auto: true);
  if (offer) rig.gateway.offer = offerOf(required: required);
  rig.gateway.events = [
    progressOf(1, 4),
    progressOf(4, 4, path: '/cache/k.apk'),
  ];
  return rig;
}

void main() {
  group('an update found on launch', () {
    test('starts downloading by itself and ends ready to install', () async {
      final rig = readyToFetch();
      await rig.controller.checkOnLaunch();
      expect(rig.gateway.downloads, ['/cache']);
      expect(rig.state.phase, UpdatePhase.ready);
      expect(rig.state.path, '/cache/k.apk');
    });

    test('is not installed without the person tapping install', () async {
      final rig = readyToFetch();
      await rig.controller.checkOnLaunch();
      expect(rig.installer.installed, isEmpty);
    });

    test('shows the available state first so the sheet can open', () async {
      final rig = readyToFetch();
      final phases = <UpdatePhase>[];
      rig.container.listen(updateControllerProvider, (previous, next) {
        phases.add(next.phase);
      });
      await rig.controller.checkOnLaunch();
      expect(phases, [
        UpdatePhase.checking,
        UpdatePhase.available,
        UpdatePhase.downloading,
        UpdatePhase.downloading,
        UpdatePhase.ready,
      ]);
    });

    test('a required update is fetched the same way', () async {
      final rig = readyToFetch(required: true);
      await rig.controller.checkOnLaunch();
      expect(rig.state.isRequired, isTrue);
      expect(rig.state.phase, UpdatePhase.ready);
    });
  });

  group('the check button', () {
    test('also fetches what it finds', () async {
      final rig = readyToFetch();
      await rig.controller.checkNow();
      expect(rig.gateway.downloads, ['/cache']);
      expect(rig.state.phase, UpdatePhase.ready);
    });

    test('downloads nothing when the app is already up to date', () async {
      final rig = readyToFetch(offer: false);
      await rig.controller.checkNow();
      expect(rig.gateway.downloads, isEmpty);
      expect(rig.state.phase, UpdatePhase.upToDate);
    });
  });

  group('when the download breaks', () {
    test('the offer stays so it can be tried again', () async {
      final rig = readyToFetch();
      rig.gateway.downloadError = StateError('cut');
      await rig.controller.checkOnLaunch();
      expect(rig.state.phase, UpdatePhase.failed);
      expect(rig.state.offer, isNotNull);
      rig.gateway.downloadError = null;
      await rig.controller.download();
      expect(rig.state.phase, UpdatePhase.ready);
    });

    test('a later launch does not start a second download on top', () async {
      final rig = readyToFetch();
      rig.gateway.downloadError = StateError('cut');
      await rig.controller.checkOnLaunch();
      await rig.controller.checkOnLaunch();
      expect(rig.gateway.checks.length, 1);
    });
  });

  group('the installed version', () {
    test('is kept in every state after a check', () async {
      final up = Rig();
      await up.controller.checkNow();
      expect(up.state.installed, '2.0.0');
      final offered = readyToFetch();
      await offered.controller.checkNow();
      expect(offered.state.installed, '2.0.0');
    });

    test('is still known when a manual check fails', () async {
      final rig = Rig();
      rig.gateway.checkError = StateError('offline');
      await rig.controller.checkNow();
      expect(rig.state.phase, UpdatePhase.failed);
      expect(rig.state.installed, '2.0.0');
    });
  });
}
