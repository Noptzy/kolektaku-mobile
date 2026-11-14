import 'dart:typed_data';

import 'package:kolektaku/data/gateways/scene_gateway.dart';
import 'package:kolektaku/platform/picture_source.dart';
import 'package:kolektaku/platform/shared_image.dart';
import 'package:kolektaku/src/rust/dto/scene.dart';

SceneMatchDto sceneMatch({
  int id = 21034,
  double? episode = 1,
  double at = 279.78,
  double similarity = 0.99,
  String? title = 'Gochuumon wa Usagi desu ka??',
  double? duration = 1418,
  String? preview = 'https://img.test/p.jpg',
}) {
  return SceneMatchDto(
    mediaId: BigInt.from(id),
    episode: episode,
    fromSecs: at - 2,
    atSecs: at,
    toSecs: at + 3,
    similarity: similarity,
    previewImageUrl: preview,
    title: title,
    durationSecs: duration,
  );
}

SceneFindingDto direct(
  SceneMatchDto best, {
  List<SceneMatchDto> others = const [],
  int? quota = 93,
}) {
  return SceneFindingDto(
    kind: SceneOutcomeKind.direct,
    best: best,
    candidates: others,
    quotaLeft: quota,
  );
}

SceneFindingDto candidatesOf(List<SceneMatchDto> list, {int? quota = 90}) {
  return SceneFindingDto(
    kind: SceneOutcomeKind.candidates,
    candidates: list,
    quotaLeft: quota,
  );
}

SceneFindingDto notFound({int? quota = 80}) {
  return SceneFindingDto(
    kind: SceneOutcomeKind.notFound,
    candidates: const [],
    quotaLeft: quota,
  );
}

SceneTargetDto watchTarget({
  int id = 21034,
  double episode = 1,
  double start = 276.78,
}) {
  return SceneTargetDto(
    kind: SceneTargetKind.watch,
    mediaId: BigInt.from(id),
    episode: episode,
    startSecs: start,
  );
}

SceneTargetDto detailTarget({
  int id = 21034,
  DetailReasonDto reason = DetailReasonDto.notAvailable,
}) {
  return SceneTargetDto(
    kind: SceneTargetKind.detail,
    mediaId: BigInt.from(id),
    reason: reason,
  );
}

class FakeSceneGateway implements SceneGateway {
  SceneFindingDto finding = notFound();
  SceneTargetDto target = watchTarget();
  Object? findError;
  Object? openError;
  Future<SceneFindingDto> Function(Uint8List image)? onFind;
  final List<int> imageSizes = [];
  final List<SceneMatchDto> opened = [];

  @override
  Future<SceneFindingDto> find(Uint8List image) async {
    imageSizes.add(image.length);
    final handler = onFind;
    if (handler != null) return handler(image);
    final error = findError;
    if (error != null) throw error;
    return finding;
  }

  @override
  Future<SceneTargetDto> open(SceneMatchDto scene) async {
    opened.add(scene);
    final error = openError;
    if (error != null) throw error;
    return target;
  }
}

class FakePictureSource implements PictureSource {
  FakePictureSource({this.gallery, this.camera});

  Uint8List? gallery;
  Uint8List? camera;
  int galleryPicks = 0;
  int cameraShots = 0;

  @override
  Future<Uint8List?> fromGallery() async {
    galleryPicks++;
    return gallery;
  }

  @override
  Future<Uint8List?> fromCamera() async {
    cameraShots++;
    return camera;
  }
}

class FakeSharedImages implements SharedImages {
  FakeSharedImages([this.image]);

  Uint8List? image;
  int takes = 0;

  @override
  Future<Uint8List?> take() async {
    takes++;
    final result = image;
    image = null;
    return result;
  }
}
