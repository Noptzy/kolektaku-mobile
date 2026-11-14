import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/data/providers/settings_providers.dart';
import 'package:kolektaku/features/watch/player/player_session.dart';
import 'package:kolektaku/features/watch/player/video_quality.dart';
import 'package:kolektaku/features/watch/player/watch_player_view.dart';
import 'package:kolektaku/platform/stream_resolver.dart';
import 'package:kolektaku/src/rust/dto/cues.dart';
import 'package:kolektaku/src/rust/dto/settings.dart';
import 'package:kolektaku/src/rust/dto/stream.dart';
import 'package:kolektaku/src/rust/dto/stream_extras.dart';
import 'package:kolektaku/features/watch/player/player_settings.dart';

import '../../widgets/widget_harness.dart';
import 'fake_engine.dart';

SubtitleDto sub(String label, String language, {String variant = 'full'}) =>
    SubtitleDto(
      label: label,
      language: language,
      variant: variant,
      url: 'https://subs.test/$label.vtt',
      isDefault: false,
    );

const source = StreamSourceDto(
  url: 'https://hls.test/master.m3u8',
  kind: 'hls',
  quality: 0,
  label: 'Otomatis',
  isDefault: true,
);

ResolvedStream stream({List<SubtitleDto> subtitles = const []}) =>
    ResolvedStream(
      set: StreamSetDto(
        sources: const [source],
        headers: const [],
        subtitles: subtitles,
        skips: [
          SkipDto(
            kind: 'intro',
            startMs: BigInt.from(72000),
            endMs: BigInt.from(158000),
          ),
        ],
      ),
      headers: const {},
    );

Future<(FakeEngine, PlayerSession)> show(
  WidgetTester tester, {
  List<SubtitleDto> subtitles = const [],
  SettingsDto? settings,
  bool controlsVisible = true,
  List<VideoQuality> qualities = const [],
  SettingPage? audioPage,
  String? audioLabel,
}) async {
  final engine = FakeEngine()..qualityList = qualities;
  final session = PlayerSession(
    engine: engine,
    stream: stream(subtitles: subtitles),
    refetch: () async => stream(subtitles: subtitles),
    settings: settings ?? defaultSettings,
    cueLoader: (url, headers) async => [
      CueDto(
        startMs: BigInt.from(1000),
        endMs: BigInt.from(3000),
        text: 'Halo dunia',
      ),
    ],
  );
  await session.start(Duration.zero);
  await tester.pump();
  addTearDown(session.close);
  await pumpAtSize(
    tester,
    WatchPlayerView(
      session: session,
      title: 'Judul',
      fullscreen: false,
      controlsVisible: controlsVisible,
      onToggleControls: () {},
      onInteract: () {},
      onFullscreen: () {},
      onBack: () {},
      audioPage: audioPage,
      audioLabel: audioLabel,
      settings: settings ?? defaultSettings,
    ),
  );
  return (engine, session);
}
