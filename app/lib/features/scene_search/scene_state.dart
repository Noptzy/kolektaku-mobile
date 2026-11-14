import 'dart:typed_data';

import '../../src/rust/dto/scene.dart';

enum SceneStatus { idle, searching, opening, candidates, notFound, failed }

class SceneLaunch {
  const SceneLaunch({required this.target, required this.match});

  final SceneTargetDto target;
  final SceneMatchDto match;
}

class SceneSearchState {
  const SceneSearchState({
    this.status = SceneStatus.idle,
    this.image,
    this.matches = const [],
    this.best,
    this.quotaLeft,
    this.error,
    this.openError,
    this.launch,
  });

  final SceneStatus status;
  final Uint8List? image;
  final List<SceneMatchDto> matches;
  final SceneMatchDto? best;
  final int? quotaLeft;
  final Object? error;
  final Object? openError;
  final SceneLaunch? launch;

  bool get busy =>
      status == SceneStatus.searching || status == SceneStatus.opening;

  SceneSearchState copyWith({
    SceneStatus? status,
    Uint8List? image,
    List<SceneMatchDto>? matches,
    SceneMatchDto? best,
    bool clearBest = false,
    int? quotaLeft,
    Object? error,
    bool clearError = false,
    Object? openError,
    bool clearOpenError = false,
    SceneLaunch? launch,
    bool clearLaunch = false,
  }) {
    return SceneSearchState(
      status: status ?? this.status,
      image: image ?? this.image,
      matches: matches ?? this.matches,
      best: clearBest ? null : (best ?? this.best),
      quotaLeft: quotaLeft ?? this.quotaLeft,
      error: clearError ? null : (error ?? this.error),
      openError: clearOpenError ? null : (openError ?? this.openError),
      launch: clearLaunch ? null : (launch ?? this.launch),
    );
  }
}
