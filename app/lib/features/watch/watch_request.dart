import '../../src/rust/dto/media.dart';

class SceneEstimate {
  const SceneEstimate({required this.at, this.sourceLength});

  final Duration at;
  final Duration? sourceLength;
}

class WatchRequest {
  const WatchRequest({
    required this.reference,
    required this.kind,
    required this.title,
    required this.episode,
    this.coverUrl,
    this.startAt,
    this.preferredSource,
    this.scene,
    this.synopsis,
  });

  final MediaRefDto reference;
  final MediaKindDto kind;
  final String title;
  final double episode;
  final String? coverUrl;
  final Duration? startAt;
  final String? preferredSource;
  final SceneEstimate? scene;
  final String? synopsis;

  WatchRequest copyWith({
    double? episode,
    Duration? startAt,
    bool clearStart = false,
    String? preferredSource,
  }) {
    return WatchRequest(
      reference: reference,
      kind: kind,
      title: title,
      episode: episode ?? this.episode,
      coverUrl: coverUrl,
      startAt: clearStart ? null : (startAt ?? this.startAt),
      preferredSource: preferredSource ?? this.preferredSource,
      scene: clearStart ? null : scene,
      synopsis: synopsis,
    );
  }
}
