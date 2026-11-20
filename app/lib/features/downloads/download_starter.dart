import '../../data/gateways/download_gateway.dart';
import '../../platform/stream_resolver.dart';
import '../../src/rust/dto/downloads.dart';
import '../../src/rust/dto/stream.dart';
import '../watch/episode_loader.dart';

typedef LoadEpisode = Future<ResolvedStream> Function(
  DownloadTargetDto target,
  String? preferred,
);

class StartReport {
  const StartReport({required this.queued, required this.failed});

  final int queued;
  final List<double> failed;
}

StreamSetDto streamForDownload(ResolvedStream stream) {
  final set = stream.set;
  final headers = set.headers.isNotEmpty
      ? set.headers
      : [
          for (final entry in stream.headers.entries)
            HeaderDto(name: entry.key, value: entry.value),
        ];
  return StreamSetDto(
    sources: set.sources,
    posterUrl: set.posterUrl,
    headers: headers,
    subtitles: set.subtitles,
    skips: set.skips,
  );
}

Future<ResolvedStream> loadWithEpisodeLoader(
  DownloadTargetDto target,
  String? preferred,
) async {
  final loaded = await EpisodeLoader().load(
    target.reference,
    target.episode,
    preferred: preferred,
  );
  return loaded.stream;
}

class DownloadStarter {
  DownloadStarter({required this.gateway, LoadEpisode? load})
    : _load = load ?? loadWithEpisodeLoader;

  final DownloadGateway gateway;
  final LoadEpisode _load;

  Future<StartReport> start(
    List<DownloadTargetDto> targets, {
    String? preferred,
    void Function(int done, int total)? onStep,
  }) async {
    var queued = 0;
    final failed = <double>[];
    for (var index = 0; index < targets.length; index++) {
      final target = targets[index];
      try {
        final stream = await _load(target, preferred);
        await gateway.enqueue(target, streamForDownload(stream));
        queued++;
      } on Object {
        failed.add(target.episode);
      }
      onStep?.call(index + 1, targets.length);
    }
    return StartReport(queued: queued, failed: failed);
  }

  Future<bool> retry(DownloadDto job) async {
    try {
      final stream = await _load(job.target, null);
      return await gateway.retry(job.id, streamForDownload(stream)) != null;
    } on Object {
      return false;
    }
  }

  Future<bool> enqueueResolved(
    DownloadTargetDto target,
    ResolvedStream stream,
  ) async {
    try {
      await gateway.enqueue(target, streamForDownload(stream));
      return true;
    } on Object {
      return false;
    }
  }
}
