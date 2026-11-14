import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/app_scope.dart';
import 'package:kolektaku/data/providers/gateway_providers.dart';
import 'package:kolektaku/features/scene_search/scene_notifier.dart';
import 'package:kolektaku/features/scene_search/scene_state.dart';
import 'package:kolektaku/platform/picture_source.dart';
import 'package:kolektaku/src/rust/dto/scene.dart';

import '../../support/fake_scene_gateway.dart';

final image = Uint8List.fromList([1, 2, 3, 4]);

class Rig {
  Rig({Uint8List? gallery, Uint8List? camera}) {
    pick = FakePictureSource(gallery: gallery, camera: camera);
    container = ProviderContainer(
      retry: noRetry,
      overrides: [
        sceneGatewayProvider.overrideWithValue(gateway),
        pictureSourceProvider.overrideWithValue(pick),
      ],
    );
    addTearDown(container.dispose);
    container.listen(sceneSearchProvider, (previous, next) {});
  }

  final FakeSceneGateway gateway = FakeSceneGateway();
  late final FakePictureSource pick;
  late final ProviderContainer container;

  SceneSearchNotifier get notifier =>
      container.read(sceneSearchProvider.notifier);

  SceneSearchState get state => container.read(sceneSearchProvider);
}

void main() {
  group('picking a picture', () {
    test('a file chosen from the gallery is searched', () async {
      final rig = Rig(gallery: image);
      rig.gateway.finding = candidatesOf([sceneMatch()]);
      await rig.notifier.pickFromGallery();
      expect(rig.pick.galleryPicks, 1);
      expect(rig.pick.cameraShots, 0);
      expect(rig.gateway.imageSizes, [4]);
    });

    test('a photo taken with the camera is searched', () async {
      final rig = Rig(camera: image);
      rig.gateway.finding = candidatesOf([sceneMatch()]);
      await rig.notifier.takePhoto();
      expect(rig.pick.cameraShots, 1);
      expect(rig.pick.galleryPicks, 0);
      expect(rig.gateway.imageSizes, [4]);
    });

    test('cancelling the picker changes nothing', () async {
      final rig = Rig();
      await rig.notifier.pickFromGallery();
      await rig.notifier.takePhoto();
      expect(rig.state.status, SceneStatus.idle);
      expect(rig.gateway.imageSizes, isEmpty);
    });

    test('a search in progress blocks another pick', () async {
      final rig = Rig(gallery: image, camera: image);
      final slow = Completer<SceneFindingDto>();
      rig.gateway.onFind = (bytes) => slow.future;
      final running = rig.notifier.search(image);
      await rig.notifier.pickFromGallery();
      await rig.notifier.takePhoto();
      expect(rig.pick.galleryPicks, 0);
      expect(rig.pick.cameraShots, 0);
      slow.complete(notFound());
      await running;
    });
  });
}
