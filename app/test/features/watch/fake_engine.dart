import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:kolektaku/features/watch/player/playback_engine.dart';
import 'package:kolektaku/features/watch/player/video_quality.dart';

class FakeEngine implements PlaybackEngine {
  final ValueNotifier<PlaybackSnapshot> _snapshot = ValueNotifier(
    const PlaybackSnapshot(),
  );
  final List<String> log = [];
  final List<PlayableSource> opened = [];
  final List<Duration> startedAt = [];
  Duration length = const Duration(minutes: 24);
  bool disposed = false;
  bool reachesStart = true;
  bool seeksLand = true;
  List<VideoQuality> qualityList = const [];
  final List<String?> selectedQualities = [];

  @override
  ValueListenable<PlaybackSnapshot> get snapshot => _snapshot;

  @override
  Widget get view => const SizedBox.expand(key: Key('fake-video'));

  void emit({
    Duration? position,
    bool? playing,
    String? failure,
    double? speed,
  }) {
    final current = _snapshot.value;
    _snapshot.value = PlaybackSnapshot(
      position: position ?? current.position,
      duration: length,
      playing: playing ?? current.playing,
      speed: speed ?? current.speed,
      failure: failure,
    );
  }

  @override
  Future<void> open(
    PlayableSource source, {
    Duration start = Duration.zero,
  }) async {
    log.add('open');
    opened.add(source);
    startedAt.add(start);
    emit(position: reachesStart ? start : null, playing: true);
  }

  @override
  Future<void> play() async {
    log.add('play');
    emit(playing: true);
  }

  @override
  Future<void> pause() async {
    log.add('pause');
    emit(playing: false);
  }

  @override
  Future<void> seekTo(Duration position) async {
    log.add('seek ${position.inSeconds}');
    if (seeksLand) emit(position: position);
  }

  @override
  Future<void> setSpeed(double speed) async {
    log.add('speed $speed');
    emit(speed: speed);
  }

  @override
  Future<List<VideoQuality>> qualities() async => qualityList;

  @override
  Future<void> selectQuality(String? id) async {
    log.add('quality $id');
    selectedQualities.add(id);
  }

  @override
  Future<void> dispose() async {
    log.add('dispose');
    disposed = true;
  }
}
