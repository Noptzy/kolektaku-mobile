import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolektaku/src/rust/dto/update.dart';

import '../../support/fake_update.dart';
import 'update_ui_support.dart';

class SlowGateway extends FakeUpdateGateway {
  final Completer<void> finish = Completer<void>();

  @override
  Stream<UpdateProgressDto> download(
    UpdateOfferDto offer,
    String folder,
  ) async* {
    await finish.future;
    yield progressOf(4, 4, path: '/cache/k.apk');
  }
}

Rig fetching({bool required = false}) {
  final rig = Rig(auto: true);
  rig.gateway.offer = offerOf(required: required);
  rig.gateway.events = [progressOf(4, 4, path: '/cache/k.apk')];
  return rig;
}

void main() {
  group('opening the app with an update out', () {
    testWidgets('shows the sheet already holding the finished download', (
      tester,
    ) async {
      final rig = fetching();
      await rig.host(tester);
      expect(find.text('Pembaruan 2.1.0'), findsOneWidget);
      expect(find.byKey(const Key('update-install')), findsOneWidget);
      expect(find.byKey(const Key('update-download')), findsNothing);
      expect(rig.gateway.downloads, ['/cache']);
    });

    testWidgets('install hands the file to the system installer', (
      tester,
    ) async {
      final rig = fetching();
      await rig.host(tester);
      await tester.tap(find.byKey(const Key('update-install')));
      await tester.pumpAndSettle();
      expect(rig.installer.installed, ['/cache/k.apk']);
    });

    testWidgets('closing the sheet keeps the file for later', (tester) async {
      final rig = fetching();
      await rig.host(tester);
      await tester.tap(find.byKey(const Key('update-later')));
      await tester.pumpAndSettle();
      expect(find.text('Pembaruan 2.1.0'), findsNothing);
      expect(find.text('isi aplikasi'), findsOneWidget);
      expect(rig.installer.installed, isEmpty);
    });

    testWidgets('a download that breaks offers a retry in the sheet', (
      tester,
    ) async {
      final rig = fetching();
      rig.gateway.events = const [];
      rig.gateway.downloadError = StateError('cut');
      await rig.host(tester);
      expect(find.byKey(const Key('update-retry')), findsOneWidget);
      expect(find.textContaining('belum berhasil'), findsOneWidget);
    });
  });

  group('a required update', () {
    testWidgets('is fetched at once and waits for install on the gate', (
      tester,
    ) async {
      final rig = fetching(required: true);
      await rig.host(tester);
      expect(find.byKey(const Key('required-update')), findsOneWidget);
      expect(find.byKey(const Key('update-install')), findsOneWidget);
      expect(rig.gateway.downloads, ['/cache']);
    });
  });

  group('the check button', () {
    testWidgets('finds the update and fetches it without another tap', (
      tester,
    ) async {
      final rig = fetching();
      await rig.page(tester);
      await tester.tap(find.byKey(const Key('update-check')));
      await tester.pumpAndSettle();
      expect(rig.gateway.downloads, ['/cache']);
      expect(find.byKey(const Key('update-install')), findsWidgets);
    });
  });

  group('an update that finishes after the sheet was closed', () {
    testWidgets('opens the sheet again so it can be installed', (tester) async {
      final slow = SlowGateway();
      slow.offer = offerOf();
      final rig = Rig(auto: true, gateway: slow);
      await rig.host(tester);
      expect(find.byKey(const Key('update-install')), findsNothing);
      await tester.tap(find.byKey(const Key('update-later')));
      await tester.pumpAndSettle();
      expect(find.text('Pembaruan 2.1.0'), findsNothing);
      slow.finish.complete();
      await tester.pumpAndSettle();
      expect(find.text('Pembaruan 2.1.0'), findsOneWidget);
      expect(find.byKey(const Key('update-install')), findsOneWidget);
    });

    testWidgets('does not reopen while the sheet is still showing', (
      tester,
    ) async {
      final slow = SlowGateway();
      slow.offer = offerOf();
      final rig = Rig(auto: true, gateway: slow);
      await rig.host(tester);
      slow.finish.complete();
      await tester.pumpAndSettle();
      expect(find.text('Pembaruan 2.1.0'), findsOneWidget);
      expect(find.byKey(const Key('update-install')), findsOneWidget);
    });
  });
}
