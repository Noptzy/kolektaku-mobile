import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/watch/player/subtitle_logic.dart';
import 'package:kolektaku/features/watch/player/video_quality.dart';
import 'package:kolektaku/src/rust/dto/settings.dart';

import 'player_logic_support.dart';

void main() {
  group('qualityChoices', () {
    test('tracks become labelled heights, best first, one per height', () {
      final choices = qualityChoices([
        (id: 'a', height: 360, bitrate: 900),
        (id: 'b', height: 1080, bitrate: 5000),
        (id: 'c', height: 720, bitrate: 3000),
        (id: 'd', height: 720, bitrate: 3500),
      ]);
      expect(choices.map((q) => q.label), ['1080p', '720p', '360p']);
      expect(choices[1].id, 'd');
    });

    test('tracks without a usable height are dropped', () {
      expect(
        qualityChoices([
          (id: 'a', height: null, bitrate: 1),
          (id: 'b', height: 0, bitrate: 1),
          (id: 'c', height: -5, bitrate: 1),
        ]),
        isEmpty,
      );
    });
  });

  group('preferredTrack', () {
    final tracks = [
      track('t1080', 1080),
      track('t720', 720),
      track('t360', 360),
    ];

    test('auto never forces a track', () {
      expect(preferredTrack(tracks, QualityDto.auto), isNull);
    });

    test('the best track not above the wish is picked', () {
      expect(preferredTrack(tracks, QualityDto.p720)?.id, 't720');
      expect(preferredTrack(tracks, QualityDto.p1080)?.id, 't1080');
      expect(preferredTrack(tracks, QualityDto.p480)?.id, 't360');
    });

    test('when everything is above the wish the lowest is used', () {
      final high = [track('a', 1080), track('b', 720)];
      expect(preferredTrack(high, QualityDto.p360)?.id, 'b');
    });

    test('a single track leaves nothing to choose', () {
      expect(preferredTrack([track('a', 720)], QualityDto.p480), isNull);
      expect(preferredTrack(const [], QualityDto.p480), isNull);
    });
  });

  group('preferredSourceIndex for separate files', () {
    final sources = [source(1080, isDefault: true), source(720), source(480)];

    test('auto keeps the default the site marked', () {
      expect(preferredSourceIndex(sources, QualityDto.auto), 0);
    });

    test('the best file not above the wish is chosen', () {
      expect(preferredSourceIndex(sources, QualityDto.p720), 1);
      expect(preferredSourceIndex(sources, QualityDto.p480), 2);
      expect(preferredSourceIndex(sources, QualityDto.p1080), 0);
    });

    test('with only larger files the smallest is chosen', () {
      expect(preferredSourceIndex(sources, QualityDto.p360), 2);
    });

    test('one source or unknown qualities fall back to the default', () {
      expect(preferredSourceIndex([source(720)], QualityDto.p360), 0);
      expect(
        preferredSourceIndex([
          source(0),
          source(0, isDefault: true),
        ], QualityDto.p480),
        1,
      );
    });
  });

  group('chooseSubtitle', () {
    final tracks = [
      sub('English', 'en', isDefault: true),
      sub('English - Forced', 'en', variant: 'forced'),
      sub('Indonesian', 'id'),
      sub('French', 'fr'),
    ];

    test('the preferred language wins', () {
      expect(
        chooseSubtitle(tracks, SubtitleLanguageDto.indonesian)?.label,
        'Indonesian',
      );
      expect(
        chooseSubtitle(tracks, SubtitleLanguageDto.english)?.label,
        'English',
      );
    });

    test('a missing language falls back to English', () {
      final noIndonesian = tracks.where((t) => t.language != 'id').toList();
      expect(
        chooseSubtitle(noIndonesian, SubtitleLanguageDto.indonesian)?.label,
        'English',
      );
    });

    test('without English the default full track is used, then the first', () {
      final other = [sub('French', 'fr'), sub('German', 'de', isDefault: true)];
      expect(
        chooseSubtitle(other, SubtitleLanguageDto.indonesian)?.label,
        'German',
      );
      final plain = [sub('French', 'fr'), sub('German', 'de')];
      expect(
        chooseSubtitle(plain, SubtitleLanguageDto.english)?.label,
        'French',
      );
    });

    test('forced and sdh tracks are never preferred over a full one', () {
      final onlyVariants = [
        sub('Indonesian - Forced', 'id', variant: 'forced'),
      ];
      expect(
        chooseSubtitle(onlyVariants, SubtitleLanguageDto.indonesian),
        isNull,
      );
      final mixed = [
        sub('Indonesian - SDH', 'id', variant: 'sdh'),
        sub('English', 'en'),
      ];
      expect(
        chooseSubtitle(mixed, SubtitleLanguageDto.indonesian)?.label,
        'English',
      );
    });

    test('off or no tracks means no subtitle', () {
      expect(chooseSubtitle(tracks, SubtitleLanguageDto.off), isNull);
      expect(chooseSubtitle(const [], SubtitleLanguageDto.indonesian), isNull);
    });
  });
}
