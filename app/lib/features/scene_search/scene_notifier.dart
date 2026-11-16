import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/gateway_providers.dart';
import '../../platform/picture_source.dart';
import '../../src/rust/dto/scene.dart';
import 'scene_state.dart';

class SceneSearchNotifier extends Notifier<SceneSearchState> {
  int _request = 0;

  @override
  SceneSearchState build() {
    Future.microtask(_loadQuota);
    return const SceneSearchState();
  }

  Future<void> _loadQuota() async {
    try {
      final left = await ref.read(sceneGatewayProvider).quotaLeft();
      if (!ref.mounted || left == null || state.quotaLeft != null) return;
      state = state.copyWith(quotaLeft: left);
    } on Object {
      return;
    }
  }

  Future<void> pickFromGallery() {
    return _pick((source) => source.fromGallery());
  }

  Future<void> takePhoto() {
    return _pick((source) => source.fromCamera());
  }

  Future<void> _pick(
    Future<Uint8List?> Function(PictureSource source) choose,
  ) async {
    if (state.busy) return;
    final image = await choose(ref.read(pictureSourceProvider));
    if (image != null) await search(image);
  }

  Future<void> search(Uint8List image) async {
    final request = ++_request;
    state = SceneSearchState(
      status: SceneStatus.searching,
      image: image,
      quotaLeft: state.quotaLeft,
    );
    try {
      final finding = await ref.read(sceneGatewayProvider).find(image);
      if (request != _request) return;
      final best = finding.best;
      state = state.copyWith(
        status: finding.kind == SceneOutcomeKind.notFound
            ? SceneStatus.notFound
            : SceneStatus.candidates,
        matches: [?best, ...finding.candidates],
        best: best,
        clearBest: best == null,
        quotaLeft: finding.quotaLeft,
      );
    } on Object catch (error) {
      if (request != _request) return;
      state = state.copyWith(status: SceneStatus.failed, error: error);
    }
  }

  Future<void> retry() {
    final image = state.image;
    if (image == null) return Future.value();
    return search(image);
  }

  Future<void> choose(SceneMatchDto match) async {
    final request = _request;
    state = state.copyWith(status: SceneStatus.opening, clearOpenError: true);
    try {
      final target = await ref.read(sceneGatewayProvider).open(match);
      if (request != _request) return;
      state = state.copyWith(
        launch: SceneLaunch(target: target, match: match),
      );
    } on Object catch (error) {
      if (request != _request) return;
      state = state.copyWith(status: SceneStatus.candidates, openError: error);
    }
  }

  void launched() {
    state = state.copyWith(status: SceneStatus.candidates, clearLaunch: true);
  }

  void reset() {
    _request++;
    state = SceneSearchState(quotaLeft: state.quotaLeft);
  }
}

final sceneSearchProvider =
    NotifierProvider.autoDispose<SceneSearchNotifier, SceneSearchState>(
      SceneSearchNotifier.new,
    );
