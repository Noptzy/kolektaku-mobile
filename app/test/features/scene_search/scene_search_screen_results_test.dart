import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/routes.dart';
import 'package:kolektaku/data/providers/gateway_providers.dart';
import 'package:kolektaku/features/detail/detail_request.dart';
import 'package:kolektaku/features/scene_search/scene_launch.dart';
import 'package:kolektaku/features/scene_search/scene_search_screen.dart';
import 'package:kolektaku/platform/picture_source.dart';
import 'package:kolektaku/src/rust/dto/scene.dart';
import 'package:kolektaku/src/rust/error.dart';

import '../../support/fake_scene_gateway.dart';
import '../../support/screen_harness.dart';
import '../../support/tiny_image.dart';

class Opened {
  Opened(this.harness, this.gateway, this.pictures);

  final ScreenHarness harness;
  final FakeSceneGateway gateway;
  final FakePictureSource pictures;
}

Future<Opened> open(
  WidgetTester tester, {
  void Function(FakeSceneGateway gateway)? prepare,
  bool withImage = true,
  bool settle = true,
}) async {
  final harness = ScreenHarness();
  final gateway = FakeSceneGateway();
  final pictures = FakePictureSource(
    gallery: withImage ? tinyPng : null,
    camera: withImage ? tinyPng : null,
  );
  prepare?.call(gateway);
  await harness.pump(
    tester,
    const SceneSearchScreen(),
    settle: settle,
    extra: [
      sceneGatewayProvider.overrideWithValue(gateway),
      pictureSourceProvider.overrideWithValue(pictures),
    ],
  );
  return Opened(harness, gateway, pictures);
}

Future<void> pickImage(WidgetTester tester) async {
  await tester.tap(find.text('Pilih dari berkas'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a title nobody has opens the detail with a note', (
    tester,
  ) async {
    final opened = await open(
      tester,
      prepare: (gateway) {
        gateway.finding = direct(sceneMatch(title: 'Judul Detail'));
        gateway.target = detailTarget();
      },
    );
    await pickImage(tester);
    await tester.tap(find.text('Judul Detail'));
    await tester.pumpAndSettle();
    final visit = opened.harness.visits.single;
    expect(visit.path, Routes.detail);
    expect((visit.extra! as DetailRequest).notice, notAvailableNotice);
  });
  testWidgets('nothing found says so and offers camera and files again', (
    tester,
  ) async {
    final opened = await open(
      tester,
      prepare: (gateway) => gateway.finding = notFound(quota: 77),
    );
    await pickImage(tester);
    expect(find.text('Belum ketemu'), findsOneWidget);
    expect(find.text('Coba tangkapan layar yang lebih jelas.'), findsOneWidget);
    expect(find.text('Sisa pencarian gambar hari ini: 77'), findsOneWidget);
    expect(find.text('Ambil foto'), findsOneWidget);
    await tester.tap(find.text('Pilih dari berkas'));
    await tester.pumpAndSettle();
    expect(opened.pictures.galleryPicks, 2);
  });
  testWidgets('the daily limit is explained and offers no pointless retry', (
    tester,
  ) async {
    await open(
      tester,
      prepare: (gateway) => gateway.findError = BridgeError(
        kind: BridgeErrorKind.quotaExceeded,
        detail: 'x',
      ),
    );
    await pickImage(tester);
    expect(
      find.textContaining('Batas pencarian gambar hari ini'),
      findsOneWidget,
    );
    expect(find.text('Coba lagi'), findsNothing);
  });
  testWidgets('a lost connection can be retried', (tester) async {
    final opened = await open(
      tester,
      prepare: (gateway) => gateway.findError = BridgeError(
        kind: BridgeErrorKind.network,
        detail: 'x',
      ),
    );
    await pickImage(tester);
    expect(find.text('Tidak ada koneksi'), findsOneWidget);
    opened.gateway.findError = null;
    opened.gateway.finding = candidatesOf([sceneMatch(title: 'Ketemu')]);
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Ketemu'), findsOneWidget);
  });
  testWidgets('a failure to open shows its message and keeps the list', (
    tester,
  ) async {
    await open(
      tester,
      prepare: (gateway) {
        gateway.finding = candidatesOf([sceneMatch(title: 'Judul')]);
        gateway.openError = BridgeError(
          kind: BridgeErrorKind.network,
          detail: 'x',
        );
      },
    );
    await pickImage(tester);
    await tester.tap(find.text('Judul'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Tidak bisa terhubung'), findsOneWidget);
    expect(find.text('Judul'), findsOneWidget);
  });
  testWidgets('the picture is previewed while and after searching', (
    tester,
  ) async {
    await open(
      tester,
      prepare: (gateway) => gateway.finding = candidatesOf([sceneMatch()]),
    );
    expect(find.byType(Image), findsNothing);
    await pickImage(tester);
    expect(find.byType(Image), findsWidgets);
  });
  testWidgets('searching shows progress while waiting', (tester) async {
    final slow = Completer<SceneFindingDto>();
    await open(
      tester,
      prepare: (gateway) => gateway.onFind = (_) => slow.future,
    );
    await tester.tap(find.text('Pilih dari berkas'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Mencari adegan...'), findsOneWidget);
    slow.complete(notFound());
    await tester.pumpAndSettle();
    expect(find.text('Mencari adegan...'), findsNothing);
  });
  testWidgets('a picture handed in at the start is searched at once', (
    tester,
  ) async {
    final harness = ScreenHarness();
    final gateway = FakeSceneGateway()
      ..finding = candidatesOf([sceneMatch(title: 'Dibagikan')]);
    await harness.pump(
      tester,
      SceneSearchScreen(initialImage: tinyPng),
      extra: [
        sceneGatewayProvider.overrideWithValue(gateway),
        pictureSourceProvider.overrideWithValue(FakePictureSource()),
      ],
    );
    expect(gateway.imageSizes, [tinyPng.length]);
    expect(find.text('Dibagikan'), findsOneWidget);
  });
}
