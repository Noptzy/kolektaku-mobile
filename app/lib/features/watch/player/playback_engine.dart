import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'video_quality.dart';

class PlayableSource {
  const PlayableSource({required this.url, this.headers = const {}});

  final String url;
  final Map<String, String> headers;
}

class PlaybackSnapshot {
  const PlaybackSnapshot({
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.playing = false,
    this.buffering = false,
    this.speed = 1.0,
    this.failure,
  });

  final Duration position;
  final Duration duration;
  final bool playing;
  final bool buffering;
  final double speed;
  final String? failure;

  double get fraction {
    if (duration.inMilliseconds <= 0) return 0;
    final value = position.inMilliseconds / duration.inMilliseconds;
    return value.clamp(0.0, 1.0);
  }
}

abstract class PlaybackEngine {
  ValueListenable<PlaybackSnapshot> get snapshot;

  Widget get view;

  Future<void> open(PlayableSource source, {Duration start = Duration.zero});

  Future<void> play();

  Future<void> pause();

  Future<void> seekTo(Duration position);

  Future<void> setSpeed(double speed);

  Future<List<VideoQuality>> qualities() async => const [];

  Future<void> selectQuality(String? id) async {}

  Future<void> dispose();
}
