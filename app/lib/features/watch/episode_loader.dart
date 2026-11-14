import '../../platform/stream_resolver.dart';
import '../../src/rust/api/detail.dart' as detail;
import '../../src/rust/api/play.dart' as core;
import '../../src/rust/dto/media.dart';
import '../../src/rust/dto/sources.dart';
import '../../src/rust/dto/stream.dart';

typedef OpenEpisode = Future<PlaybackDto> Function({
  required MediaRefDto reference,
  required double episode,
  String? preferred,
  required List<String> exclude,
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
  }) : _open = open ?? core.openEpisode,
       _resolve = resolve ?? const StreamResolver().resolve,
       _units = units ?? detail.units;

  final OpenEpisode _open;
  final ResolveServer _resolve;
  final LoadUnits _units;
  final int serversPerSource;
  final int maxSources;

  Future<LoadedEpisode> load(
    MediaRefDto reference,
    double episode, {
    String? preferred,
    List<String> exclude = const [],
  }) async {
    final failed = <String>[...exclude];
    Object? lastError;
    for (var round = 0; round < maxSources; round++) {
      final PlaybackDto playback;
      try {
        playback = await _open(
          reference: reference,
          episode: episode,
          preferred: failed.isEmpty ? preferred : null,
          exclude: List.of(failed),
        );
      } on Object catch (error) {
        throw lastError ?? error;
      }
      final working = await _firstWorkingServer(playback, (error) {
        lastError = error;
      });
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
    try {
      final result = await _units(reference: reference, source: source);
      return result.units;
    } on Object {
      return const [];
    }
  }

  Future<LoadedEpisode> useServer(LoadedEpisode loaded, String serverId) async {
    final stream = await _resolve(
      source: loaded.playback.source,
      episodeId: loaded.playback.unit.id,
      server: serverId,
    );
    return LoadedEpisode(
      playback: loaded.playback,
      stream: stream,
      serverId: serverId,
    );
  }

  Future<ResolvedStream> refresh(LoadedEpisode loaded) => _resolve(
    source: loaded.playback.source,
    episodeId: loaded.playback.unit.id,
    server: loaded.serverId,
  );

  Future<({String server, ResolvedStream stream})?> _firstWorkingServer(
    PlaybackDto playback,
    void Function(Object error) onError,
  ) async {
    for (final server in playback.servers.take(serversPerSource)) {
      try {
        final stream = await _resolve(
          source: playback.source,
          episodeId: playback.unit.id,
          server: server.id,
        );
        return (server: server.id, stream: stream);
      } on Object catch (error) {
        onError(error);
      }
    }
    return null;
  }
}
