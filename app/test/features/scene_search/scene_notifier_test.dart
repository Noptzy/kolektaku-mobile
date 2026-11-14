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
import 'package:kolektaku/src/rust/error.dart';

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
  test('starts idle', () {
    expect(Rig().state.status, SceneStatus.idle);
  });
  test('a direct hit is listed first but never opened by itself', () async {
    final rig = Rig();
    final best = sceneMatch();
    final other = sceneMatch(id: 5, similarity: 0.85);
    rig.gateway.finding = direct(best, others: [other]);
    await rig.notifier.search(image);
    expect(rig.gateway.opened, isEmpty);
    expect(rig.state.launch, isNull);
    expect(rig.state.status, SceneStatus.candidates);
    expect(rig.state.matches, [best, other]);
    expect(rig.state.best, best);
    expect(rig.state.quotaLeft, 93);
    expect(rig.state.image, image);
  });
  test('choosing the best match opens its target', () async {
    final rig = Rig();
    final best = sceneMatch();
    rig.gateway.finding = direct(best);
    await rig.notifier.search(image);
    await rig.notifier.choose(best);
    expect(rig.gateway.opened, [best]);
    expect(rig.state.launch!.target.episode, 1);
    expect(rig.state.launch!.match, best);
  });
  test('candidates wait for a choice and open nothing', () async {
    final rig = Rig();
    final list = [sceneMatch(), sceneMatch(id: 2, similarity: 0.82)];
    rig.gateway.finding = candidatesOf(list);
    await rig.notifier.search(image);
    expect(rig.state.status, SceneStatus.candidates);
    expect(rig.state.matches, list);
    expect(rig.state.best, isNull);
    expect(rig.gateway.opened, isEmpty);
    expect(rig.state.launch, isNull);
  });
  test('choosing a candidate opens that scene', () async {
    final rig = Rig();
    final chosen = sceneMatch(id: 2, similarity: 0.82);
    rig.gateway.finding = candidatesOf([sceneMatch(), chosen]);
    await rig.notifier.search(image);
    await rig.notifier.choose(chosen);
    expect(rig.gateway.opened, [chosen]);
    expect(rig.state.launch!.match, chosen);
  });
  test('nothing found says so and keeps the quota', () async {
    final rig = Rig();
    rig.gateway.finding = notFound(quota: 77);
    await rig.notifier.search(image);
    expect(rig.state.status, SceneStatus.notFound);
    expect(rig.state.quotaLeft, 77);
    expect(rig.state.matches, isEmpty);
  });
  test('a failed search is kept so it can be retried', () async {
    final rig = Rig();
    rig.gateway.findError = BridgeError(
      kind: BridgeErrorKind.quotaExceeded,
      detail: 'x',
    );
    await rig.notifier.search(image);
    expect(rig.state.status, SceneStatus.failed);
    expect(rig.state.error, isA<BridgeError>());
    rig.gateway.findError = null;
    rig.gateway.finding = candidatesOf([sceneMatch()]);
    await rig.notifier.retry();
    expect(rig.state.status, SceneStatus.candidates);
    expect(rig.state.error, isNull);
    expect(rig.gateway.imageSizes, [4, 4]);
  });
  test('retry without an image does nothing', () async {
    final rig = Rig();
    await rig.notifier.retry();
    expect(rig.gateway.imageSizes, isEmpty);
  });
  test('a failure to open keeps the list and reports the error', () async {
    final rig = Rig();
    rig.gateway.finding = candidatesOf([sceneMatch()]);
    await rig.notifier.search(image);
    rig.gateway.openError = BridgeError(
      kind: BridgeErrorKind.network,
      detail: 'x',
    );
    await rig.notifier.choose(sceneMatch());
    expect(rig.state.status, SceneStatus.candidates);
    expect(rig.state.openError, isA<BridgeError>());
    expect(rig.state.matches.length, 1);
    expect(rig.state.launch, isNull);
  });
  test('a later try clears the open error', () async {
    final rig = Rig();
    rig.gateway.finding = candidatesOf([sceneMatch()]);
    await rig.notifier.search(image);
    rig.gateway.openError = BridgeError(
      kind: BridgeErrorKind.network,
      detail: 'x',
    );
    await rig.notifier.choose(sceneMatch());
    rig.gateway.openError = null;
    await rig.notifier.choose(sceneMatch());
    expect(rig.state.openError, isNull);
    expect(rig.state.launch, isNotNull);
  });
  test('once launched the results stay for coming back', () async {
    final rig = Rig();
    rig.gateway.finding = direct(sceneMatch());
    await rig.notifier.search(image);
    await rig.notifier.choose(sceneMatch());
    rig.notifier.launched();
    expect(rig.state.launch, isNull);
    expect(rig.state.status, SceneStatus.candidates);
    expect(rig.state.matches.length, 1);
  });
  test('reset goes back to the start', () async {
    final rig = Rig();
    rig.gateway.finding = direct(sceneMatch());
    await rig.notifier.search(image);
    rig.notifier.reset();
    expect(rig.state.status, SceneStatus.idle);
    expect(rig.state.image, isNull);
    expect(rig.state.matches, isEmpty);
  });
  test('a slow older search never overwrites a newer one', () async {
    final rig = Rig();
    final slow = Completer<SceneFindingDto>();
    final older = Uint8List.fromList([9, 9]);
    rig.gateway.onFind = (bytes) {
      if (bytes.length == 2) return slow.future;
      return Future.value(candidatesOf([sceneMatch(id: 2)]));
    };
    final first = rig.notifier.search(older);
    await rig.notifier.search(image);
    slow.complete(direct(sceneMatch(id: 1)));
    await first;
    expect(rig.state.matches.single.mediaId, BigInt.two);
    expect(rig.gateway.opened, isEmpty);
  });
}
