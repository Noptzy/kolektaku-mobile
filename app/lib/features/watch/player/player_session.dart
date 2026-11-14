import 'package:flutter/foundation.dart';

import 'dart:async';

import '../../../data/providers/settings_providers.dart';
import '../../../platform/stream_resolver.dart';
import '../../../src/rust/dto/settings.dart';
import '../../../src/rust/dto/stream.dart';
import 'playback_engine.dart';
import 'player_extras.dart';
import 'progress_throttle.dart';
import 'resume_point.dart';
import 'video_quality.dart';

typedef Refetch = Future<ResolvedStream> Function();
typedef ProgressSink = void Function(Duration position, Duration length);

class PlayerSession {
  PlayerSession({
    required this.engine,
    required this._stream,
    required this._refetch,
    this._onProgress,
    this.skipStep = const Duration(seconds: 10),
    this.settings = defaultSettings,
    CueLoader? cueLoader,
  }) {
    extras = PlayerExtras(
      engine: engine,
      settings: settings,
      cueLoader: cueLoader ?? loadCuesFromCore,
      seek: _seek,
    );
  }

  final PlaybackEngine engine;
  final Duration skipStep;
  final SettingsDto settings;
  late final PlayerExtras extras;
  final ValueNotifier<int> quality = ValueNotifier(0);
  final ValueNotifier<String?> failure = ValueNotifier(null);

  ResolvedStream _stream;
  final Refetch _refetch;
  final ProgressSink? _onProgress;
  final ProgressThrottle _throttle = ProgressThrottle();
  final ResumePoint _resume = ResumePoint();
  bool _refetched = false;
  bool _recovering = false;
  bool _closed = false;

  List<StreamSourceDto> get sources => _stream.set.sources;

  Future<void> start(Duration startAt) async {
    quality.value = preferredSourceIndex(sources, settings.quality);
    _resume.aim(startAt);
    extras.load(_stream.set);
    engine.snapshot.addListener(_onSnapshot);
    await _open(startAt);
  }

  Future<void> _open(Duration at) async {
    final source = sources[quality.value.clamp(0, sources.length - 1)];
    await engine.open(
      PlayableSource(url: source.url, headers: _stream.headers),
      start: at,
    );
    unawaited(extras.onOpened());
  }

  void _onSnapshot() {
    final snapshot = engine.snapshot.value;
    if (snapshot.failure != null) {
      _recover(snapshot.failure!);
      return;
    }
    _resume.observe(snapshot.position);
    if (snapshot.playing) extras.onPosition(snapshot.position);
    final watched = snapshot.playing && snapshot.position > Duration.zero;
    if (watched && _throttle.shouldReport(snapshot.position)) {
      _onProgress?.call(snapshot.position, snapshot.duration);
    }
  }

  Future<void> _recover(String reason) async {
    if (_recovering || _closed) return;
    if (_refetched) {
      failure.value = reason;
      return;
    }
    _recovering = true;
    _refetched = true;
    final resumeAt = _resume.resolve(engine.snapshot.value.position);
    try {
      _stream = await _refetch();
      extras.load(_stream.set);
      quality.value = quality.value.clamp(0, sources.length - 1);
      failure.value = null;
      await _open(resumeAt);
    } on Object catch (error) {
      failure.value = error.toString();
    } finally {
      _recovering = false;
    }
  }

  Future<void> retry() async {
    failure.value = null;
    _refetched = false;
    await _recover('retry');
  }

  Future<void> togglePlay() =>
      engine.snapshot.value.playing ? engine.pause() : engine.play();

  Future<void> seekToFraction(double fraction) {
    final length = engine.snapshot.value.duration;
    return _seek(length * fraction.clamp(0.0, 1.0));
  }

  Future<void> _seek(Duration target) {
    _resume.aim(target);
    return engine.seekTo(target);
  }

  Future<void> skip(Duration delta) {
    final snapshot = engine.snapshot.value;
    final target = snapshot.position + delta;
    final limit = snapshot.duration;
    final clamped = target < Duration.zero
        ? Duration.zero
        : (limit > Duration.zero && target > limit ? limit : target);
    return _seek(clamped);
  }

  Future<void> setSpeed(double speed) => engine.setSpeed(speed);

  Future<void> selectQuality(int index) async {
    if (index == quality.value || index < 0 || index >= sources.length) return;
    final at = _resume.resolve(engine.snapshot.value.position);
    quality.value = index;
    _resume.aim(at);
    await _open(at);
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    final snapshot = engine.snapshot.value;
    if (snapshot.position > Duration.zero) {
      _onProgress?.call(snapshot.position, snapshot.duration);
    }
    engine.snapshot.removeListener(_onSnapshot);
    await engine.dispose();
    extras.dispose();
    quality.dispose();
    failure.dispose();
  }
}
