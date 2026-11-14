import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/data/providers/gateway_providers.dart';
import 'package:kolektaku/features/scene_search/scene_search_screen.dart';
import 'package:kolektaku/platform/picture_source.dart';

import '../../support/fake_scene_gateway.dart';
import '../../support/screen_harness.dart';
import '../../support/tiny_image.dart';

Future<({FakeSceneGateway gateway, FakePictureSource pictures})> openWith(
  WidgetTester tester, {
  required bool openCamera,
  bool withPhoto = true,
}) async {
  final harness = ScreenHarness();
  final gateway = FakeSceneGateway();
  final pictures = FakePictureSource(
    gallery: tinyPng,
    camera: withPhoto ? tinyPng : null,
  );
  await harness.pump(
    tester,
    SceneSearchScreen(openCamera: openCamera),
    extra: [
      sceneGatewayProvider.overrideWithValue(gateway),
      pictureSourceProvider.overrideWithValue(pictures),
    ],
  );
  return (gateway: gateway, pictures: pictures);
}

void main() {
  testWidgets('entering from the camera button opens the camera at once', (
    tester,
  ) async {
    final opened = await openWith(tester, openCamera: true);
    expect(opened.pictures.cameraShots, 1);
    expect(opened.pictures.galleryPicks, 0);
  });

  testWidgets('a photo taken goes straight to the search', (tester) async {
    final opened = await openWith(tester, openCamera: true);
    expect(opened.gateway.imageSizes.length, 1);
  });

  testWidgets('cancelling the camera leaves the choice of file on screen', (
    tester,
  ) async {
    final opened = await openWith(tester, openCamera: true, withPhoto: false);
    expect(opened.pictures.cameraShots, 1);
    expect(find.text('Pilih dari berkas'), findsOneWidget);
    expect(find.text('Ambil foto'), findsOneWidget);
    expect(opened.gateway.imageSizes, isEmpty);
  });

  testWidgets('without the flag nothing opens by itself', (tester) async {
    final opened = await openWith(tester, openCamera: false);
    expect(opened.pictures.cameraShots, 0);
    expect(opened.gateway.imageSizes, isEmpty);
  });

  testWidgets('a shared picture is searched and the camera stays shut', (
    tester,
  ) async {
    final harness = ScreenHarness();
    final gateway = FakeSceneGateway();
    final pictures = FakePictureSource();
    await harness.pump(
      tester,
      SceneSearchScreen(initialImage: tinyPng, openCamera: true),
      extra: [
        sceneGatewayProvider.overrideWithValue(gateway),
        pictureSourceProvider.overrideWithValue(pictures),
      ],
    );
    expect(pictures.cameraShots, 0);
    expect(gateway.imageSizes.length, 1);
  });
}
