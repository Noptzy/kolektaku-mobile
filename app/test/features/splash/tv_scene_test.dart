import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/splash/tv_scene.dart';

void main() {
  group('channels', () {
    test('the channel changes every fraction of a second and wraps around', () {
      expect(channelAt(0), 0);
      expect(channelAt(channelSeconds * 0.99), 0);
      expect(channelAt(channelSeconds), 1);
      expect(channelAt(channelSeconds * 3.5), 3);
      expect(channelAt(channelSeconds * channelCount), 0);
      expect(channelAt(channelSeconds * (channelCount + 2)), 2);
    });

    test('the phase runs from nothing to almost one inside a channel', () {
      expect(channelPhase(0), 0);
      expect(channelPhase(channelSeconds / 2), closeTo(0.5, 0.0001));
      expect(channelPhase(channelSeconds * 2.25), closeTo(0.25, 0.0001));
      expect(channelPhase(channelSeconds * 0.999), lessThan(1));
    });

    test('every channel has two colours and they differ', () {
      for (var channel = 0; channel < channelCount; channel++) {
        final colors = channelColors(channel);
        expect(colors.length, 2);
        expect(colors.first, isNot(colors.last));
      }
      final firsts = {
        for (var c = 0; c < channelCount; c++) channelColors(c).first,
      };
      expect(firsts.length, channelCount);
    });

    test('a channel index outside the list still has colours', () {
      expect(channelColors(channelCount + 1), channelColors(1));
    });

    test('the glow follows the channel on screen', () {
      expect(glowOf(0), channelColors(0).first);
      expect(glowOf(channelSeconds), channelColors(1).first);
    });
  });

  group('snow', () {
    test('only the start of a channel shows static', () {
      expect(isSnowing(0), isTrue);
      expect(isSnowing(channelSeconds * staticShare * 0.9), isTrue);
      expect(isSnowing(channelSeconds * 0.5), isFalse);
      expect(isSnowing(channelSeconds * 1.01), isTrue);
    });

    test('the noise is the same for the same moment and moves on', () {
      expect(noiseAt(5, 3), noiseAt(5, 3));
      expect(noiseAt(5, 3), isNot(noiseAt(6, 3)));
      expect(noiseSeed(0.5), noiseSeed(0.5));
      expect(noiseSeed(0.5), isNot(noiseSeed(0.6)));
    });

    test('noise values stay between nothing and one', () {
      for (var seed = 0; seed < 50; seed++) {
        for (var index = 0; index < 20; index++) {
          final value = noiseAt(seed, index);
          expect(value, inInclusiveRange(0, 1));
        }
      }
    });
  });

  group('antenna', () {
    test('it swings both ways and stays bounded', () {
      var low = 0.0;
      var high = 0.0;
      for (var t = 0.0; t < 3.2; t += 0.05) {
        final swing = antennaSwing(t);
        low = swing < low ? swing : low;
        high = swing > high ? swing : high;
      }
      expect(low, lessThan(-0.9));
      expect(high, greaterThan(0.9));
    });
  });

  test('the whole scene loops after every channel was shown once', () {
    expect(sceneLoopSeconds, channelSeconds * channelCount);
    expect(channelAt(sceneLoopSeconds + 0.1), channelAt(0.1));
  });
}
