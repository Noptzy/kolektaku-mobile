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
    this.audio,
    this.expectedMinutes,
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
  final String? audio;
  final int? expectedMinutes;
  final SceneEstimate? scene;
  final String? synopsis;

  WatchRequest copyWith({
    double? episode,
    Duration? startAt,
    bool clearStart = false,
    String? preferredSource,
    String? audio,
    bool clearAudio = false,
  }) {
    return WatchRequest(
      reference: reference,
      kind: kind,
      title: title,
      episode: episode ?? this.episode,
      coverUrl: coverUrl,
      startAt: clearStart ? null : (startAt ?? this.startAt),
      preferredSource: preferredSource ?? this.preferredSource,
      audio: clearAudio ? null : (audio ?? this.audio),
      expectedMinutes: expectedMinutes,
      scene: clearStart ? null : scene,
      synopsis: synopsis,
    );
  }
}
