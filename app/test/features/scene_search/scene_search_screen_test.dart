import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/routes.dart';
import 'package:kolektaku/data/providers/gateway_providers.dart';
import 'package:kolektaku/features/scene_search/scene_search_screen.dart';
import 'package:kolektaku/features/watch/watch_request.dart';
import 'package:kolektaku/platform/picture_source.dart';
import 'package:kolektaku/widgets/poster.dart';

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
  testWidgets('starts by asking for a picture and being honest about limits', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Cari dari gambar'), findsOneWidget);
    expect(find.text('Ambil foto'), findsOneWidget);
    expect(find.text('Pilih dari berkas'), findsOneWidget);
    expect(find.textContaining('Hanya frame anime asli'), findsOneWidget);
  });
  testWidgets('a picked picture is searched and candidates are listed', (
    tester,
  ) async {
    final opened = await open(
      tester,
      prepare: (gateway) => gateway.finding = candidatesOf([
        sceneMatch(episode: 5, at: 279, similarity: 0.86, title: 'Judul Satu'),
        sceneMatch(
          id: 2,
          episode: 2,
          at: 61,
          similarity: 0.82,
          title: 'Judul Dua',
        ),
      ]),
    );
    await pickImage(tester);
    expect(opened.gateway.imageSizes, [tinyPng.length]);
    expect(find.text('Mungkin ini adegannya'), findsOneWidget);
    expect(find.text('Judul Satu'), findsOneWidget);
    expect(find.text('Ep 5 · 04:39'), findsOneWidget);
    expect(find.text('86%'), findsOneWidget);
    expect(find.text('Ep 2 · 01:01'), findsOneWidget);
    expect(find.text('Sisa pencarian gambar hari ini: 90'), findsOneWidget);
  });
  testWidgets('a direct hit is listed first and nothing opens by itself', (
    tester,
  ) async {
    final opened = await open(
      tester,
      prepare: (gateway) {
        gateway.finding = direct(
          sceneMatch(at: 279.78, title: 'Terbaik'),
          others: [sceneMatch(id: 2, title: 'Lainnya', similarity: 0.85)],
        );
        gateway.target = watchTarget(episode: 1, start: 276.78);
      },
    );
    await pickImage(tester);
    expect(find.text('Mungkin ini adegannya'), findsOneWidget);
    expect(find.text('Terbaik'), findsOneWidget);
    expect(find.text('Lainnya'), findsOneWidget);
    expect(opened.gateway.opened, isEmpty);
    expect(opened.harness.visits, isEmpty);
  });
  testWidgets('tapping the best match opens the player at that moment', (
    tester,
  ) async {
    final opened = await open(
      tester,
      prepare: (gateway) {
        gateway.finding = direct(sceneMatch(at: 279.78, title: 'Terbaik'));
        gateway.target = watchTarget(episode: 1, start: 276.78);
      },
    );
    await pickImage(tester);
    await tester.tap(find.text('Terbaik'));
    await tester.pumpAndSettle();
    final visit = opened.harness.visits.single;
    expect(visit.path, Routes.watch);
    final request = visit.extra! as WatchRequest;
    expect(request.episode, 1);
    expect(request.startAt, const Duration(milliseconds: 276780));
    expect(request.scene!.at, const Duration(milliseconds: 279780));
    expect(request.scene!.sourceLength, const Duration(seconds: 1418));
  });
  testWidgets('the camera takes a photo and searches it', (tester) async {
    final opened = await open(
      tester,
      prepare: (gateway) =>
          gateway.finding = candidatesOf([sceneMatch(title: 'Dari kamera')]),
    );
    await tester.tap(find.text('Ambil foto'));
    await tester.pumpAndSettle();
    expect(opened.pictures.cameraShots, 1);
    expect(opened.pictures.galleryPicks, 0);
    expect(find.text('Dari kamera'), findsOneWidget);
  });
  testWidgets('every row shows the preview frame from the search service', (
    tester,
  ) async {
    await open(
      tester,
      prepare: (gateway) => gateway.finding = candidatesOf([
        sceneMatch(title: 'Satu', preview: 'https://img.test/frame-1.jpg'),
        sceneMatch(
          id: 2,
          title: 'Dua',
          preview: 'https://img.test/frame-2.jpg',
        ),
      ]),
    );
    await pickImage(tester);
    final urls = tester
        .widgetList<Poster>(find.byType(Poster))
        .map((poster) => poster.url)
        .toList();
    expect(urls, [
      'https://img.test/frame-1.jpg',
      'https://img.test/frame-2.jpg',
    ]);
  });
  testWidgets('tapping a candidate opens it', (tester) async {
    final opened = await open(
      tester,
      prepare: (gateway) {
        gateway.finding = candidatesOf([
          sceneMatch(title: 'Pilihan Saya', similarity: 0.85),
        ]);
        gateway.target = watchTarget(episode: 7, start: 10);
      },
    );
    await pickImage(tester);
    await tester.tap(find.text('Pilihan Saya'));
    await tester.pumpAndSettle();
    expect(opened.gateway.opened.single.title, 'Pilihan Saya');
    expect((opened.harness.visits.single.extra! as WatchRequest).episode, 7);
  });
}
