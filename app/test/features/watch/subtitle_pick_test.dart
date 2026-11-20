import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/watch/player/translation_logic.dart';

import 'player_extras_support.dart';
import 'subtitle_translation_support.dart';

void main() {
  group('a track picked by hand', () {
    test('plays in its own language without being translated', () async {
      final rig = TranslationRig(
        tracks: [sub('Indonesian', 'id'), sub('English', 'en')],
      );
      await rig.start();
      rig.requests.clear();
      await rig.session.extras.pickSubtitle(rig.session.extras.available.last);
      await pumpEventQueue();
      expect(rig.requests.map((request) => request.translate), [false]);
      expect(rig.shown, ['Hello']);
      final cues = rig.session.extras.subtitleCues;
      expect(cues.status.value, TranslationStatus.none);
      expect(cues.canTranslate, isTrue);
    });

    test('can still be translated when asked', () async {
      final rig = TranslationRig(
        tracks: [sub('Indonesian', 'id'), sub('English', 'en')],
      );
      await rig.start();
      await rig.session.extras.pickSubtitle(rig.session.extras.available.last);
      await pumpEventQueue();
      final cues = rig.session.extras.subtitleCues;
      await cues.translateNow();
      expect(rig.requests.last.translate, isTrue);
      expect(rig.shown, ['Halo']);
      expect(cues.status.value, TranslationStatus.translated);
      expect(cues.canTranslate, isFalse);
    });

    test('picking the track already on screen keeps its translation', () async {
      final rig = TranslationRig();
      await rig.start();
      final asked = rig.requests.length;
      await rig.session.extras.pickSubtitle(rig.session.extras.subtitle.value);
      await pumpEventQueue();
      expect(rig.requests.length, asked);
      expect(rig.shown, ['Halo']);
    });

    test('a track in the target language offers no translation', () async {
      final rig = TranslationRig(
        tracks: [sub('English', 'en'), sub('Indonesian', 'id')],
      );
      await rig.start();
      final indonesian = rig.session.extras.available.firstWhere(
        (track) => track.language == 'id',
      );
      await rig.session.extras.pickSubtitle(indonesian);
      await pumpEventQueue();
      expect(rig.session.extras.subtitleCues.canTranslate, isFalse);
    });
  });
}
