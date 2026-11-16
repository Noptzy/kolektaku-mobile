import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/providers/settings_providers.dart';
import '../../platform/pip.dart';
import '../../src/rust/dto/settings.dart';
import '../../src/rust/dto/sources.dart';
import '../detail/episode_window.dart';
import 'auto_next.dart';
import 'episode_loader.dart';
import 'player/end_watcher.dart';
import 'player/playback_engine.dart';
import 'player/player_extras.dart';
import 'player/player_session.dart';
import 'player/watch_pip.dart';
import 'resume_gate.dart';
import 'watch_progress.dart';
import 'watch_request.dart';
import 'watch_units.dart';

part 'watch_controller_switching.dart';

class WatchController extends ChangeNotifier {
  WatchController({
    required this.request,
    required this.loader,
    required this.engineFactory,
    required this.progress,
    required this.pip,
    Duration autoNextDelay = const Duration(seconds: 5),
    this.settings = defaultSettings,
    this.cueLoader,
  }) {
    autoNext = AutoNext(delay: autoNextDelay, onElapsed: _playNext);
    endWatcher = EndWatcher(
      onEnd: () {
        if (settings.autoNext && next != null) autoNext.start();
      },
      onLeave: autoNext.cancel,
    );
  }

  final EpisodeLoader loader;
  final PlaybackEngine Function() engineFactory;
  final WatchProgress progress;
  final PipHost pip;
  final SettingsDto settings;
  final CueLoader? cueLoader;
  late final AutoNext autoNext;
  late final EndWatcher endWatcher;
  late final WatchUnits _units = WatchUnits(loader: loader, onChange: _notify);
  final ResumeGate _gate = ResumeGate();

  WatchRequest request;
  PlayerSession? session;
  WatchPip? _watchPip;
  LoadedEpisode? loaded;
  Object? error;
  bool inPip = false;
  int _generation = 0;
  bool _disposed = false;

  double get current => loaded?.playback.unit.number ?? request.episode;

  Duration? get resumePrompt => _gate.waitingFor;

  List<UnitDto> get units => _units.list;

  UnitDto? get next => unitAfter(units, current);

  UnitDto? get previous => unitBefore(units, current);

  Future<void> load({
    List<String> exclude = const [],
    Duration? startAt,
  }) async {
    final generation = ++_generation;
    _gate.clear();
    await _teardown();
    error = null;
    loaded = null;
    _notify();
    if (units.isEmpty) {
      unawaited(_units.load(request.reference, request.preferredSource));
    }
    try {
      final result = await loader.load(
        request.reference,
        request.episode,
        preferred: request.preferredSource,
        exclude: exclude,
        audio: request.audio,
      );
      if (generation != _generation) return;
      final explicit = startAt ?? request.startAt;
      final saved = explicit == null ? await progress.resumeAt(request) : null;
      if (generation != _generation) return;
      if (saved == null) {
        await _begin(result, explicit ?? Duration.zero, generation);
      } else {
        _gate.hold(result, saved, generation);
        _notify();
      }
      if (_units.needs(result.playback.source)) {
        unawaited(_units.load(request.reference, result.playback.source));
      }
    } on Object catch (failure) {
      if (generation != _generation || _disposed) return;
      error = failure;
      _notify();
    }
  }

  Future<void> goTo(UnitDto unit) async {
    autoNext.cancel();
    request = request.copyWith(episode: unit.number, clearStart: true);
    await load();
  }

  Future<void> _begin(
    LoadedEpisode episode,
    Duration startAt,
    int generation,
  ) async {
    final watched = request;
    final fresh = PlayerSession(
      engine: engineFactory(),
      stream: episode.stream,
      settings: settings,
      cueLoader: cueLoader,
      refetch: () => loader.refresh(episode),
      onProgress: (position, length) =>
          progress.save(watched, position, length).catchError((Object _) {}),
    );
    await fresh.start(startAt);
    if (_disposed || generation != _generation) {
      await fresh.close();
      return;
    }
    final host = WatchPip(
      host: pip,
      session: fresh,
      onModeChanged: (value) {
        inPip = value;
        _notify();
      },
    );
    await host.start();
    fresh.engine.snapshot.addListener(_onSnapshot);
    endWatcher.reset();
    session = fresh;
    loaded = episode;
    _watchPip = host;
    error = null;
    _notify();
  }

  void _onSnapshot() {
    final snapshot = session?.engine.snapshot.value;
    if (snapshot != null) endWatcher.feed(snapshot);
  }

  void _playNext() {
    final target = next;
    if (target != null) goTo(target);
  }

  Future<void> _teardown() async {
    final old = session;
    session = null;
    old?.engine.snapshot.removeListener(_onSnapshot);
    _watchPip?.dispose();
    _watchPip = null;
    inPip = false;
    await old?.close();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _units.close();
    _gate.clear();
    _generation++;
    autoNext.dispose();
    session?.engine.snapshot.removeListener(_onSnapshot);
    _watchPip?.dispose();
    session?.close();
    super.dispose();
  }
}
