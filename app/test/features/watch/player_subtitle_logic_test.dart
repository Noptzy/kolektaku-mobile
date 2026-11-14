import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/watch/player/skip_logic.dart';
import 'package:kolektaku/features/watch/player/subtitle_logic.dart';

import 'player_logic_support.dart';

void main() {
  group('subtitle names and order', () {
    test('known languages are named in Indonesian with their variant', () {
      expect(subtitleTitle(sub('Indonesian', 'id')), 'Indonesia');
      expect(
        subtitleTitle(sub('English - SDH', 'en', variant: 'sdh')),
        'Inggris (tunarungu)',
      );
      expect(
        subtitleTitle(sub('French - Forced', 'fr', variant: 'forced')),
        'Prancis (dialog asing)',
      );
    });

    test('an unknown language keeps its own label', () {
      expect(subtitleTitle(sub('NOB', null)), 'NOB');
    });

    test(
      'the list starts with Indonesian, then English, full tracks first',
      () {
        final ordered = orderedSubtitles([
          sub('French', 'fr'),
          sub('English - Forced', 'en', variant: 'forced'),
          sub('English', 'en'),
          sub('Indonesian', 'id'),
          sub('Arabic', 'ar'),
        ]);
        expect(ordered.map((t) => t.label), [
          'Indonesian',
          'English',
          'English - Forced',
          'Arabic',
          'French',
        ]);
      },
    );
  });

  group('cueAt', () {
    final cues = [
      cue(1000, 2000, 'a'),
      cue(3000, 4000, 'b'),
      cue(4000, 5000, 'c'),
    ];

    test('the cue covering the position is found', () {
      expect(cueAt(cues, const Duration(milliseconds: 1500))?.text, 'a');
      expect(cueAt(cues, const Duration(milliseconds: 3000))?.text, 'b');
      expect(cueAt(cues, const Duration(milliseconds: 4000))?.text, 'c');
    });

    test('gaps, before the first and after the last give nothing', () {
      expect(cueAt(cues, const Duration(milliseconds: 500)), isNull);
      expect(cueAt(cues, const Duration(milliseconds: 2500)), isNull);
      expect(cueAt(cues, const Duration(milliseconds: 5000)), isNull);
      expect(cueAt(const [], Duration.zero), isNull);
    });
  });

  group('activeSkip', () {
    final skips = [
      skip('intro', 72000, 158000),
      skip('outro', 1326000, 1510000),
    ];

    test('inside a range it is active, with a little lead in', () {
      expect(activeSkip(skips, const Duration(seconds: 100))?.kind, 'intro');
      expect(
        activeSkip(skips, const Duration(milliseconds: 71600))?.kind,
        'intro',
      );
      expect(activeSkip(skips, const Duration(seconds: 1400))?.kind, 'outro');
    });

    test('outside every range nothing is active', () {
      expect(activeSkip(skips, const Duration(seconds: 10)), isNull);
      expect(activeSkip(skips, const Duration(milliseconds: 71000)), isNull);
      expect(activeSkip(skips, const Duration(milliseconds: 157800)), isNull);
      expect(activeSkip(const [], const Duration(seconds: 100)), isNull);
    });

    test('labels and targets follow the range', () {
      expect(skipLabel(skips[0]), 'Lewati intro');
      expect(skipLabel(skips[1]), 'Lewati outro');
      expect(skipTarget(skips[0]), const Duration(seconds: 158));
      expect(skipKey(skips[0]), isNot(skipKey(skips[1])));
    });
  });
}
