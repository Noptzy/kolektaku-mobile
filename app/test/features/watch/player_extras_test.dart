import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/data/providers/settings_providers.dart';
import 'package:kolektaku/features/settings/settings_edit.dart';
import 'package:kolektaku/features/watch/player/player_session.dart';
import 'package:kolektaku/features/watch/player/video_quality.dart';
import 'package:kolektaku/platform/stream_resolver.dart';
import 'package:kolektaku/src/rust/dto/cues.dart';
import 'package:kolektaku/src/rust/dto/settings.dart';
import 'package:kolektaku/src/rust/dto/stream.dart';

import 'fake_engine.dart';
import 'player_extras_support.dart';

void main() {
  group('resolution of an adaptive stream', () {
    final tracks = [
      const VideoQuality(id: 't1080', height: 1080, label: '1080p'),
      const VideoQuality(id: 't720', height: 720, label: '720p'),
      const VideoQuality(id: 't360', height: 360, label: '360p'),
    ];

    test(
      'the tracks of the engine are offered and nothing is forced on auto',
      () async {
        final rig = Rig()..engine.qualityList = tracks;
        await rig.start();
        expect(rig.session.extras.tracks.value.length, 3);
        expect(rig.session.extras.trackId.value, isNull);
        expect(rig.engine.selectedQualities, isEmpty);
      },
    );

    test('a preferred resolution is applied once the stream is open', () async {
      final rig = Rig(
        settings: defaultSettings.copyWith(quality: QualityDto.p720),
      )..engine.qualityList = tracks;
      await rig.start();
      expect(rig.engine.selectedQualities, ['t720']);
      expect(rig.session.extras.trackId.value, 't720');
    });

    test('picking a track and going back to auto reach the engine', () async {
      final rig = Rig()..engine.qualityList = tracks;
      await rig.start();
      await rig.session.extras.selectTrack('t360');
      await rig.session.extras.selectTrack(null);
      expect(rig.engine.selectedQualities, ['t360', null]);
      expect(rig.session.extras.trackId.value, isNull);
    });

    test('an engine without tracks leaves the list empty', () async {
      final rig = Rig();
      await rig.start();
      expect(rig.session.extras.tracks.value, isEmpty);
    });
  });

  group('requests carry the headers of the player page', () {
    test('the stream opens with the referer and origin of the embed', () async {
      final rig = Rig();
      await rig.start();
      expect(rig.engine.opened.single.url, 'https://hls.test/master.m3u8');
      expect(rig.engine.opened.single.headers, {
        'referer': 'https://player.test/',
        'origin': 'https://player.test',
      });
    });

    test('a stream without its own headers falls back to the episode page', () {
      final plain = StreamSetDto(
        sources: [hlsSource()],
        headers: const [],
        subtitles: const [],
        skips: const [],
      );
      expect(requestHeaders(plain, 'https://site.test/ep/1'), {
        'Referer': 'https://site.test/ep/1',
      });
    });

    test('own headers replace the fallback instead of adding to it', () {
      final own = StreamSetDto(
        sources: [hlsSource()],
        headers: hlsHeaders,
        subtitles: const [],
        skips: const [],
      );
      final headers = requestHeaders(own, 'https://site.test/ep/1');
      expect(headers.keys, ['referer', 'origin']);
      expect(headers.containsKey('Referer'), isFalse);
    });
  });

  group('subtitles', () {
    test('the preferred language is loaded with the same headers', () async {
      final rig = Rig(
        cues: {
          'https://subs.test/Indonesian.vtt': [cue(1000, 2000, 'Halo')],
        },
      );
      await rig.start();
      expect(rig.session.extras.subtitle.value?.label, 'Indonesian');
      expect(rig.asked, ['https://subs.test/Indonesian.vtt']);
      expect(rig.sentHeaders.single['referer'], 'https://player.test/');
      expect(rig.session.extras.cues.value.single.text, 'Halo');
    });

    test('turning them off in settings loads nothing', () async {
      final rig = Rig(
        settings: defaultSettings.copyWith(
          subtitleLanguage: SubtitleLanguageDto.off,
        ),
      );
      await rig.start();
      expect(rig.session.extras.subtitle.value, isNull);
      expect(rig.asked, isEmpty);
    });

    test('English can be preferred instead', () async {
      final rig = Rig(
        settings: defaultSettings.copyWith(
          subtitleLanguage: SubtitleLanguageDto.english,
        ),
      );
      await rig.start();
      expect(rig.session.extras.subtitle.value?.label, 'English');
    });

    test(
      'choosing another track replaces the cues and off clears them',
      () async {
        final rig = Rig(
          cues: {
            'https://subs.test/Indonesian.vtt': [cue(0, 1000, 'id')],
            'https://subs.test/English.vtt': [cue(0, 1000, 'en')],
          },
        );
        await rig.start();
        await rig.session.extras.selectSubtitle(
          rig.session.extras.available.first,
        );
        expect(rig.session.extras.cues.value.single.text, 'en');
        await rig.session.extras.selectSubtitle(null);
        expect(rig.session.extras.cues.value, isEmpty);
        expect(rig.session.extras.subtitle.value, isNull);
      },
    );

    test(
      'a slow answer for an old choice never overwrites the new one',
      () async {
        final slow = Completer<List<CueDto>>();
        final engine = FakeEngine();
        final session = PlayerSession(
          engine: engine,
          stream: hlsStream(),
          refetch: () async => hlsStream(),
          cueLoader: (url, headers) => url.contains('Indonesian')
              ? slow.future
              : Future.value([cue(0, 1000, 'en')]),
        );
        await session.start(Duration.zero);
        await session.extras.selectSubtitle(session.extras.available.first);
        slow.complete([cue(0, 1000, 'terlambat')]);
        await pumpEventQueue();
        expect(session.extras.cues.value.single.text, 'en');
      },
    );

    test(
      'a failing download leaves playback alone and the cues empty',
      () async {
        final rig = Rig(failLoads: true);
        await rig.start();
        expect(rig.session.extras.cues.value, isEmpty);
        expect(rig.session.failure.value, isNull);
      },
    );

    test('a stream without subtitles has no subtitle button', () async {
      final rig = Rig(
        stream: ResolvedStream(
          set: StreamSetDto(
            sources: [hlsSource()],
            headers: const [],
            subtitles: const [],
            skips: const [],
          ),
          headers: const {},
        ),
      );
      await rig.start();
      expect(rig.session.extras.hasSubtitles, isFalse);
    });
  });
}
