import '../../core/ttl_cache.dart';
import '../../platform/stream_resolver.dart';
import '../../src/rust/dto/media.dart';
import '../../src/rust/dto/sources.dart';
import '../../src/rust/dto/stream.dart';

const playbackLifetime = Duration(minutes: 10);
const streamLifetime = Duration(minutes: 8);

class EpisodeCache {
  EpisodeCache({Clock? now})
    : playbacks = TtlCache(lifetime: playbackLifetime, now: now),
      streams = TtlCache(lifetime: streamLifetime, now: now),
      unitLists = TtlCache(lifetime: playbackLifetime, now: now);

  static final EpisodeCache shared = EpisodeCache();

  final TtlCache<String, PlaybackDto> playbacks;
  final TtlCache<String, ResolvedStream> streams;
  final TtlCache<String, List<UnitDto>> unitLists;

  static String reference(MediaRefDto reference) =>
      '${reference.kind.name}:${reference.id}:${reference.source}:'
      '${reference.item}';

  static String playback(
    MediaRefDto reference,
    double episode,
    String? preferred,
  ) => '${EpisodeCache.reference(reference)}|$episode|${preferred ?? ''}';

  static String stream(String source, String episodeId, String server) =>
      '$source|$episodeId|$server';

  static String units(MediaRefDto reference, String? source) =>
      '${EpisodeCache.reference(reference)}|${source ?? ''}';

  void clear() {
    playbacks.clear();
    streams.clear();
    unitLists.clear();
  }
}
