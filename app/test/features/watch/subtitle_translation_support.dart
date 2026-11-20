import 'dart:async';

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
import 'player_extras_support.dart';

ResolvedStream streamWith(List<SubtitleDto> tracks) {
  final set = StreamSetDto(
    sources: [hlsSource()],
    headers: hlsHeaders,
    subtitles: tracks,
    skips: const [],
  );
  return ResolvedStream(
    set: set,
    headers: requestHeaders(set, 'https://page.test/ep'),
  );
}

class TranslationRig {
  TranslationRig({
    this.tracks = const [],
    this.translated,
    this.gate,
    SettingsDto? settings,
  }) {
    final stream = streamWith(tracks.isEmpty ? [sub('English', 'en')] : tracks);
    session = PlayerSession(
      engine: engine,
      stream: stream,
      refetch: () async => stream,
      settings: settings ?? defaultSettings,
      cueLoader: (request) async {
        requests.add(request);
        if (!request.translate) return plan([cue(0, 1000, 'Hello')]);
        final waiting = gate;
        if (waiting != null) return waiting.future;
        return translated ?? plan([cue(0, 1000, 'Halo')], translated: true);
      },
    );
  }

  final List<SubtitleDto> tracks;
  final CuePlanDto? translated;
  final Completer<CuePlanDto>? gate;
  final FakeEngine engine = FakeEngine();
  final List<CueRequest> requests = [];
  late final PlayerSession session;

  Future<void> start() async {
    await session.start(Duration.zero);
    await pumpEventQueue();
  }

  List<String> get shown =>
      session.extras.cues.value.map((cue) => cue.text).toList();
}
