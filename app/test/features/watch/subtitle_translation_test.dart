import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/translation_labels.dart';
import 'package:kolektaku/data/providers/settings_providers.dart';
import 'package:kolektaku/features/watch/player/cue_loading.dart';
import 'package:kolektaku/features/watch/player/player_session.dart';
import 'package:kolektaku/features/settings/settings_edit.dart';
import 'package:kolektaku/features/watch/player/subtitle_logic.dart';
import 'package:kolektaku/features/watch/player/translation_logic.dart';
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

void main() {
  group('an English track with translation into Indonesian', () {
    test('the original shows first and the translation replaces it', () async {
      final rig = TranslationRig();
      await rig.start();
      expect(rig.requests.map((request) => request.translate), [false, true]);
      expect(rig.shown, ['Halo']);
      expect(
        rig.session.extras.subtitleCues.status.value,
        TranslationStatus.translated,
      );
    });

    test(
      'the track language and playback position go with the request',
      () async {
        final rig = TranslationRig();
        await rig.start();
        expect(rig.requests.last.language, 'en');
        expect(rig.requests.last.positionMs, 0);
        expect(rig.requests.last.url, 'https://subs.test/English.vtt');
      },
    );

    test(
      'while the translation is pending the original is on screen',
      () async {
        final gate = Completer<CuePlanDto>();
        final rig = TranslationRig(gate: gate);
        await rig.start();
        expect(rig.shown, ['Hello']);
        expect(
          rig.session.extras.subtitleCues.status.value,
          TranslationStatus.working,
        );
        gate.complete(plan([cue(0, 1000, 'Halo')], translated: true));
        await pumpEventQueue();
        expect(rig.shown, ['Halo']);
      },
    );

    test(
      'showing the original and back never asks the service again',
      () async {
        final rig = TranslationRig();
        await rig.start();
        final asked = rig.requests.length;
        final cues = rig.session.extras.subtitleCues;
        expect(cues.canToggleOriginal, isTrue);
        cues.toggleOriginal();
        expect(rig.shown, ['Hello']);
        cues.toggleOriginal();
        expect(rig.shown, ['Halo']);
        expect(rig.requests.length, asked);
      },
    );

    test('choosing another track starts from the original again', () async {
      final rig = TranslationRig(
        tracks: [sub('English', 'en'), sub('French', 'fr')],
      );
      await rig.start();
      rig.session.extras.subtitleCues.toggleOriginal();
      await rig.session.extras.selectSubtitle(
        rig.session.extras.available.last,
      );
      await pumpEventQueue();
      expect(rig.session.extras.subtitleCues.showingOriginal.value, isFalse);
    });
  });

  group('when no translation is needed', () {
    test(
      'a track already in the target language is never translated',
      () async {
        final rig = TranslationRig(tracks: [sub('Indonesian', 'id')]);
        await rig.start();
        expect(rig.requests.map((request) => request.translate), [false]);
        expect(rig.shown, ['Hello']);
        expect(
          rig.session.extras.subtitleCues.status.value,
          TranslationStatus.none,
        );
      },
    );

    test('with translation off only the original is loaded', () async {
      final rig = TranslationRig(
        settings: defaultSettings.copyWith(
          translation: TranslationLanguageDto.off,
        ),
      );
      await rig.start();
      expect(rig.requests.map((request) => request.translate), [false]);
      expect(rig.shown, ['Hello']);
    });

    test(
      'a plan that came back untranslated and unfailed shows the original',
      () async {
        final rig = TranslationRig(translated: plan([cue(0, 1000, 'Hello')]));
        await rig.start();
        expect(rig.shown, ['Hello']);
        expect(rig.session.extras.subtitleCues.notice.value, isNull);
      },
    );

    test('subtitles turned off by the user load nothing', () async {
      final rig = TranslationRig(
        settings: defaultSettings.copyWith(
          subtitleLanguage: SubtitleLanguageDto.off,
        ),
      );
      await rig.start();
      expect(rig.requests, isEmpty);
    });
  });

  group('when the service fails', () {
    test('the original stays and one notice is raised', () async {
      final rig = TranslationRig(
        translated: plan([cue(0, 1000, 'Hello')], failed: true),
      );
      await rig.start();
      expect(rig.shown, ['Hello']);
      final cues = rig.session.extras.subtitleCues;
      expect(cues.status.value, TranslationStatus.failed);
      expect(cues.notice.value, contains('teks asli'));
      expect(cues.canToggleOriginal, isFalse);
    });

    test('a busy service says when it will be back', () async {
      final rig = TranslationRig(
        translated: plan(
          [cue(0, 1000, 'Hello')],
          failed: true,
          retryAt: 1700000000,
        ),
      );
      await rig.start();
      final notice = rig.session.extras.subtitleCues.notice.value;
      expect(notice, contains('Layanan terjemahan sedang sibuk'));
      expect(notice, contains('pukul'));
    });

    test(
      'picking another track in the same episode does not repeat the notice',
      () async {
        final rig = TranslationRig(
          tracks: [sub('English', 'en'), sub('French', 'fr')],
          translated: plan([cue(0, 1000, 'Hello')], failed: true),
        );
        await rig.start();
        final cues = rig.session.extras.subtitleCues;
        final first = cues.notice.value;
        var raised = 0;
        cues.notice.addListener(() => raised++);
        await rig.session.extras.selectSubtitle(
          rig.session.extras.available.last,
        );
        await pumpEventQueue();
        expect(cues.notice.value, first);
        expect(raised, 0);
      },
    );

    test('a new episode may raise the notice again', () async {
      final rig = TranslationRig(
        translated: plan([cue(0, 1000, 'Hello')], failed: true),
      );
      await rig.start();
      final cues = rig.session.extras.subtitleCues;
      cues.newEpisode();
      expect(cues.notice.value, isNull);
    });
  });

  group('choosing the track', () {
    final tracks = [sub('English', 'en'), sub('Indonesian', 'id')];

    test('a human-made track in the target language comes first', () {
      final chosen = chooseSubtitle(
        tracks,
        SubtitleLanguageDto.english,
        translation: TranslationLanguageDto.indonesian,
      );
      expect(chosen?.language, 'id');
    });

    test('without such a track the preferred one is the base', () {
      final chosen = chooseSubtitle(
        [sub('English', 'en'), sub('French', 'fr')],
        SubtitleLanguageDto.english,
        translation: TranslationLanguageDto.indonesian,
      );
      expect(chosen?.language, 'en');
    });

    test('translation off keeps the old choice', () {
      final chosen = chooseSubtitle(tracks, SubtitleLanguageDto.english);
      expect(chosen?.language, 'en');
    });

    test('off from the user means no track at all', () {
      final chosen = chooseSubtitle(
        tracks,
        SubtitleLanguageDto.off,
        translation: TranslationLanguageDto.indonesian,
      );
      expect(chosen, isNull);
    });

    test('Filipino tracks are found under their track code', () {
      final chosen = chooseSubtitle(
        [sub('English', 'en'), sub('Filipino', 'fil')],
        SubtitleLanguageDto.english,
        translation: TranslationLanguageDto.filipino,
      );
      expect(chosen?.language, 'fil');
    });
  });

  group('wording', () {
    test('the translated entry is named after the target language', () {
      expect(
        translatedTitle(TranslationLanguageDto.indonesian),
        'Indonesia · terjemahan otomatis',
      );
      expect(
        translatingTitle(TranslationLanguageDto.japanese),
        'Jepang · Menerjemahkan…',
      );
    });

    test('the clock reads hours and minutes with a dot', () {
      expect(clockLabel(DateTime(2026, 1, 1, 9, 5)), '09.05');
      expect(clockLabel(DateTime(2026, 1, 1, 21, 40)), '21.40');
    });

    test('every language has a track code except off', () {
      for (final language in TranslationLanguageDto.values) {
        expect(
          trackLanguageOf(language) == null,
          language == TranslationLanguageDto.off,
        );
        expect(translationLanguageNames[language], isNotNull);
      }
    });
  });
}
