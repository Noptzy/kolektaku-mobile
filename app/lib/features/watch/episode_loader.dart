import '../../platform/stream_resolver.dart';
import '../../src/rust/api/detail.dart' as detail;
import '../../src/rust/api/play.dart' as core;
import '../../src/rust/dto/media.dart';
import '../../src/rust/dto/sources.dart';
import '../../src/rust/dto/stream.dart';
import 'episode_cache.dart';

typedef OpenEpisode = Future<PlaybackDto> Function({
  required MediaRefDto reference,
  required double episode,
  String? preferred,
  required List<String> exclude,
  String? audio,
});

typedef ResolveServer = Future<ResolvedStream> Function({
  required String source,
  required String episodeId,
  required String server,
});

typedef LoadUnits = Future<UnitsDto> Function({
  required MediaRefDto reference,
  String? source,
});

class LoadedEpisode {
  const LoadedEpisode({
    required this.playback,
    required this.stream,
    required this.serverId,
    this.switchedFrom,
  });

  final PlaybackDto playback;
  final ResolvedStream stream;
  final String serverId;
  final String? switchedFrom;
}

class EpisodeLoader {
  EpisodeLoader({
    OpenEpisode? open,
    ResolveServer? resolve,
    LoadUnits? units,
    this.serversPerSource = 3,
    this.maxSources = 6,
    EpisodeCache? cache,
  }) : _open = open ?? core.openEpisode,
       _resolve = resolve ?? const StreamResolver().resolve,
       _units = units ?? detail.units,
       _cache =
           cache ??
           (open == null && resolve == null && units == null
               ? EpisodeCache.shared
               : EpisodeCache());

  final OpenEpisode _open;
  final ResolveServer _resolve;
  final LoadUnits _units;
  final int serversPerSource;
  final int maxSources;
  final EpisodeCache _cache;

  Future<LoadedEpisode> load(
    MediaRefDto reference,
    double episode, {
    String? preferred,
    List<String> exclude = const [],
    String? audio,
  }) async {
    final failed = <String>[...exclude];
    Object? lastError;
    for (var round = 0; round < maxSources; round++) {
      final PlaybackDto playback;
      final key = EpisodeCache.playback(reference, episode, preferred, audio);
      final cached = failed.isEmpty ? _cache.playbacks.get(key) : null;
      try {
        playback =
            cached ??
            await _open(
              reference: reference,
              episode: episode,
              preferred: failed.isEmpty ? preferred : null,
              exclude: List.of(failed),
              audio: audio,
            );
      } on Object catch (error) {
        throw lastError ?? error;
      }
      if (failed.isEmpty) _cache.playbacks.put(key, playback);
      final working = await _firstWorkingServer(playback, (error) {
        lastError = error;
      });
      if (working == null && failed.isEmpty) _cache.playbacks.remove(key);
      if (working != null) {
        final from = playback.switchedFrom ?? failed.firstOrNull;
        return LoadedEpisode(
          playback: playback,
          stream: working.stream,
          serverId: working.server,
          switchedFrom: from,
        );
      }
      failed.add(playback.source);
    }
    throw lastError ?? StateError('no source could play this episode');
  }

  Future<List<UnitDto>> unitsOrEmpty(
    MediaRefDto reference, {
    String? source,
  }) async {
    final key = EpisodeCache.units(reference, source);
    final cached = _cache.unitLists.get(key);
    if (cached != null) return cached;
    try {
      final result = await _units(reference: reference, source: source);
      if (result.units.isNotEmpty) _cache.unitLists.put(key, result.units);
      return result.units;
    } on Object {
      return const [];
    }
  }

  Future<ResolvedStream> _resolved(
    String source,
    String episodeId,
    String server, {
    bool fresh = false,
  }) async {
    final key = EpisodeCache.stream(source, episodeId, server);
    final cached = fresh ? null : _cache.streams.get(key);
    if (cached != null) return cached;
    final stream = await _resolve(
      source: source,
      episodeId: episodeId,
      server: server,
    );
    _cache.streams.put(key, stream);
    return stream;
  }

  Future<LoadedEpisode> useServer(LoadedEpisode loaded, String serverId) async {
    final stream = await _resolved(
      loaded.playback.source,
      loaded.playback.unit.id,
      serverId,
    );
    return LoadedEpisode(
      playback: loaded.playback,
      stream: stream,
      serverId: serverId,
    );
  }

  Future<ResolvedStream> refresh(LoadedEpisode loaded) => _resolved(
    loaded.playback.source,
    loaded.playback.unit.id,
    loaded.serverId,
    fresh: true,
  );

  Future<({String server, ResolvedStream stream})?> _firstWorkingServer(
    PlaybackDto playback,
    void Function(Object error) onError,
  ) async {
    for (final server in playback.servers.take(serversPerSource)) {
      try {
        final stream = await _resolved(
          playback.source,
          playback.unit.id,
          server.id,
        );
        return (server: server.id, stream: stream);
      } on Object catch (error) {
        onError(error);
      }
    }
    return null;
  }
}
