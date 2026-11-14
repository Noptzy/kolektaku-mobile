import 'dart:typed_data';

import '../../src/rust/api/scene.dart' as api;
import '../../src/rust/dto/scene.dart';

abstract interface class SceneGateway {
  Future<SceneFindingDto> find(Uint8List image);

  Future<SceneTargetDto> open(SceneMatchDto scene);
}

class BridgeSceneGateway implements SceneGateway {
  const BridgeSceneGateway();

  @override
  Future<SceneFindingDto> find(Uint8List image) => api.findScene(image: image);

  @override
  Future<SceneTargetDto> open(SceneMatchDto scene) =>
      api.openScene(scene: scene);
}
