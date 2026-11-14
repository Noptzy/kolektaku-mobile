import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

import 'playback_engine.dart';
import 'start_guard.dart';
import 'video_quality.dart';

class VideoPlayerEngine implements PlaybackEngine {
  static int _liveControllers = 0;

  static int get liveControllers => _liveControllers;

  final ValueNotifier<PlaybackSnapshot> _snapshot = ValueNotifier(
    const PlaybackSnapshot(),
  );
  VideoPlayerController? _controller;
  double _speed = 1.0;
  bool _disposed = false;
  bool _userSeeked = false;

  @override
  ValueListenable<PlaybackSnapshot> get snapshot => _snapshot;

  @override
  Widget get view => ValueListenableBuilder<PlaybackSnapshot>(
    valueListenable: _snapshot,
    builder: (context, snapshot, child) {
      final controller = _controller;
      if (controller == null || !controller.value.isInitialized) {
        return const SizedBox.shrink();
      }
      return Center(
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
      );
    },
  );

  @override
  Future<void> open(
    PlayableSource source, {
    Duration start = Duration.zero,
  }) async {
    await _release();
    _userSeeked = false;
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(source.url),
      httpHeaders: source.headers,
    );
    _controller = controller;
    _liveControllers++;
    controller.addListener(_publish);
    try {
      await controller.initialize();
      await controller.setPlaybackSpeed(_speed);
      if (start > Duration.zero) await controller.seekTo(start);
      await controller.play();
    } on Object catch (error) {
      _emit(PlaybackSnapshot(failure: error.toString(), speed: _speed));
      return;
    }
    _publish();
    unawaited(
      holdStart(
        start: start,
        position: () => controller.value.position,
        seek: controller.seekTo,
        active: () =>
            !_disposed && identical(_controller, controller) && !_userSeeked,
      ),
    );
  }

  void _publish() {
    final controller = _controller;
    if (controller == null) return;
    final value = controller.value;
    _emit(
      PlaybackSnapshot(
        position: value.position,
        duration: value.duration,
        playing: value.isPlaying,
        buffering: value.isBuffering,
        speed: value.playbackSpeed,
        failure: value.hasError ? value.errorDescription : null,
      ),
    );
  }

  void _emit(PlaybackSnapshot snapshot) {
    if (!_disposed) _snapshot.value = snapshot;
  }

  @override
  Future<void> play() async => _controller?.play();

  @override
  Future<void> pause() async => _controller?.pause();

  @override
  Future<void> seekTo(Duration position) async {
    _userSeeked = true;
    await _controller?.seekTo(position);
  }

  @override
  Future<void> setSpeed(double speed) async {
    _speed = speed;
    await _controller?.setPlaybackSpeed(speed);
  }

  @override
  Future<List<VideoQuality>> qualities() async {
    final controller = _controller;
    if (controller == null || !controller.isVideoTrackSupportAvailable()) {
      return const [];
    }
    final tracks = await controller.getVideoTracks();
    return qualityChoices([
      for (final track in tracks)
        (id: track.id, height: track.height, bitrate: track.bitrate),
    ]);
  }

  @override
  Future<void> selectQuality(String? id) async {
    final controller = _controller;
    if (controller == null) return;
    if (id == null) {
      await controller.selectVideoTrack(null);
      return;
    }
    final tracks = await controller.getVideoTracks();
    for (final track in tracks) {
      if (track.id == id) {
        await controller.selectVideoTrack(track);
        return;
      }
    }
  }

  Future<void> _release() async {
    final controller = _controller;
    _controller = null;
    if (controller == null) return;
    controller.removeListener(_publish);
    await controller.dispose();
    _liveControllers--;
  }

  @override
  Future<void> dispose() async {
    await _release();
    _disposed = true;
    _snapshot.dispose();
  }
}
