import 'package:kolektaku/platform/stream_resolver.dart';
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:kolektaku/src/rust/dto/sources.dart';
import 'package:kolektaku/src/rust/dto/stream.dart';

final reference = MediaRefDto(
  kind: MediaRefKind.catalog,
  id: BigInt.from(1),
  source: '',
  item: '',
);

PlaybackDto playbackOn(
  String source, {
  String? switchedFrom,
  int servers = 2,
  double episode = 1,
  bool variants = false,
}) => PlaybackDto(
  source: source,
  item: '$source-item',
  unit: UnitDto(
    id: '$source-ep-${episode.round()}',
    number: episode,
    label: 'Episode ${episode.round()}',
  ),
  servers: [
    for (var i = 1; i <= servers; i++)
      ServerDto(
        id: 'srv$i',
        label: 'Srv $i',
        variant: variants ? (i <= servers ~/ 2 ? 'sub' : 'dub') : null,
      ),
  ],
  switchedFrom: switchedFrom,
);

ResolvedStream streamOf(String name) => ResolvedStream(
  set: StreamSetDto(
    sources: [
      StreamSourceDto(
        url: 'https://$name.test/v-720.mp4',
        kind: 'mp4',
        quality: 720,
        label: '720p',
        isDefault: true,
      ),
      StreamSourceDto(
        url: 'https://$name.test/v-480.mp4',
        kind: 'mp4',
        quality: 480,
        label: '480p',
        isDefault: false,
      ),
    ],
    headers: const [],
    subtitles: const [],
    skips: const [],
  ),
  headers: const {'Referer': 'https://site.test/ep'},
);
