import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/data/providers/settings_providers.dart';
import 'package:kolektaku/features/settings/settings_edit.dart';

import 'player_extras_support.dart';

void main() {
  group('skipping intro and outro', () {
    test(
      'entering the intro makes the button appear and leaving hides it',
      () async {
        final rig = Rig();
        await rig.start();
        rig.engine.emit(position: const Duration(seconds: 80), playing: true);
        expect(rig.session.extras.current.value?.kind, 'intro');
        rig.engine.emit(position: const Duration(seconds: 200), playing: true);
        expect(rig.session.extras.current.value, isNull);
      },
    );

    test('tapping the button jumps to the end of the range', () async {
      final rig = Rig();
      await rig.start();
      rig.engine.emit(position: const Duration(seconds: 80), playing: true);
      await rig.session.extras.skipCurrent();
      expect(rig.engine.log, contains('seek 158'));
      expect(rig.session.extras.current.value, isNull);
    });

    test(
      'automatic skipping jumps once and not again after seeking back',
      () async {
        final rig = Rig(settings: defaultSettings.copyWith(autoSkip: true));
        await rig.start();
        rig.engine.emit(position: const Duration(seconds: 80), playing: true);
        await pumpEventQueue();
        expect(rig.engine.log.where((entry) => entry == 'seek 158').length, 1);
        rig.engine.emit(position: const Duration(seconds: 100), playing: true);
        await pumpEventQueue();
        expect(rig.engine.log.where((entry) => entry == 'seek 158').length, 1);
      },
    );

    test('with automatic skipping off nothing jumps on its own', () async {
      final rig = Rig();
      await rig.start();
      rig.engine.emit(position: const Duration(seconds: 80), playing: true);
      await pumpEventQueue();
      expect(rig.engine.log.any((entry) => entry.startsWith('seek')), isFalse);
    });

    test('the outro works like the intro', () async {
      final rig = Rig(settings: defaultSettings.copyWith(autoSkip: true));
      await rig.start();
      rig.engine.emit(position: const Duration(seconds: 1400), playing: true);
      await pumpEventQueue();
      expect(rig.engine.log, contains('seek 1510'));
    });

    test('while paused no range is reported', () async {
      final rig = Rig();
      await rig.start();
      rig.engine.emit(position: const Duration(seconds: 80), playing: false);
      expect(rig.session.extras.current.value, isNull);
    });
  });

  group('after the stream is fetched again', () {
    test('subtitles and ranges come from the new stream', () async {
      final rig = Rig(
        cues: {
          'https://subs.test/Indonesian.vtt': [cue(0, 1000, 'baru')],
        },
      );
      await rig.start();
      rig.engine.emit(failure: 'network');
      await pumpEventQueue();
      expect(rig.asked.length, 2);
      expect(rig.session.extras.cues.value.single.text, 'baru');
    });
  });
}
