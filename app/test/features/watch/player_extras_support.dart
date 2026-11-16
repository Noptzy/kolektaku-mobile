import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/data/providers/settings_providers.dart';
import 'package:kolektaku/features/watch/player/cue_loading.dart';
import 'package:kolektaku/features/watch/player/player_session.dart';
import 'package:kolektaku/platform/stream_resolver.dart';
import 'package:kolektaku/src/rust/dto/cues.dart';
import 'package:kolektaku/src/rust/dto/settings.dart';
import 'package:kolektaku/src/rust/dto/stream.dart';
import 'package:kolektaku/src/rust/dto/stream_extras.dart';

import 'fake_engine.dart';

const hlsHeaders = [
  HeaderDto(name: 'referer', value: 'https://player.test/'),
  HeaderDto(name: 'origin', value: 'https://player.test'),
];

SubtitleDto sub(String label, String language, {bool isDefault = false}) =>
    SubtitleDto(
      label: label,
      language: language,
      variant: 'full',
      url: 'https://subs.test/$label.vtt',
      isDefault: isDefault,
    );

CueDto cue(int start, int end, String text) =>
    CueDto(startMs: BigInt.from(start), endMs: BigInt.from(end), text: text);

CuePlanDto plan(
  List<CueDto> cues, {
  bool translated = false,
  bool failed = false,
  int? retryAt,
}) => CuePlanDto(
  cues: cues,
  translated: translated,
  failed: failed,
  retryAtSecs: retryAt == null ? null : BigInt.from(retryAt),
);

SkipDto skip(String kind, int start, int end) =>
    SkipDto(kind: kind, startMs: BigInt.from(start), endMs: BigInt.from(end));

StreamSourceDto hlsSource() => const StreamSourceDto(
  url: 'https://hls.test/master.m3u8',
  kind: 'hls',
  quality: 0,
  label: 'Otomatis',
  isDefault: true,
);

ResolvedStream hlsStream() => ResolvedStream(
  set: StreamSetDto(
    sources: [hlsSource()],
    headers: hlsHeaders,
    subtitles: [sub('English', 'en', isDefault: true), sub('Indonesian', 'id')],
    skips: [skip('intro', 72000, 158000), skip('outro', 1326000, 1510000)],
  ),
  headers: requestHeaders(
    StreamSetDto(
      sources: [hlsSource()],
      headers: hlsHeaders,
      subtitles: const [],
      skips: const [],
    ),
    'https://page.test/ep',
  ),
);

class Rig {
  Rig({
    SettingsDto? settings,
    ResolvedStream? stream,
    this.cues = const {},
    this.failLoads = false,
  }) {
    session = PlayerSession(
      engine: engine,
      stream: stream ?? hlsStream(),
      refetch: () async => hlsStream(),
      settings: settings ?? defaultSettings,
      cueLoader: (request) async {
        if (request.translate) {
          translateAsks.add(request);
          return plan(cues[request.url] ?? const []);
        }
        asked.add(request.url);
        sentHeaders.add({for (final h in request.headers) h.name: h.value});
        if (failLoads) throw StateError('no subtitle');
        return plan(cues[request.url] ?? const []);
      },
    );
  }

  final FakeEngine engine = FakeEngine();
  final Map<String, List<CueDto>> cues;
  final bool failLoads;
  final List<String> asked = [];
  final List<CueRequest> translateAsks = [];
  final List<Map<String, String>> sentHeaders = [];
  late final PlayerSession session;

  Future<void> start() async {
    await session.start(Duration.zero);
    await pumpEventQueue();
  }
}
