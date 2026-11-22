import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/hairline/motion.dart';

void main() {
  group('cubicBezier', () {
    test('starts at zero and ends at one, and clamps outside', () {
      final ease = cubicBezier(0.25, 0.1, 0.25, 1);
      expect(ease(0), 0);
      expect(ease(1), 1);
      expect(ease(-0.5), 0);
      expect(ease(1.5), 1);
    });

    test('the linear curve is the identity', () {
      final linear = cubicBezier(0, 0, 1, 1);
      for (final t in [0.1, 0.25, 0.5, 0.75, 0.9]) {
        expect(linear(t), closeTo(t, 1e-3));
      }
    });
  });

  group('easeLift', () {
    test('never goes backwards', () {
      var previous = 0.0;
      for (var i = 1; i <= 100; i++) {
        final value = easeLift(i / 100);
        expect(value, greaterThanOrEqualTo(previous - 1e-9));
        previous = value;
      }
    });

    test('leaves fast and lands softly', () {
      expect(easeLift(0.25), greaterThan(0.25));
      expect(easeLift(0.5), greaterThan(0.5));
      expect(easeLift(0.95), greaterThan(0.95));
    });
  });

  group('HlTween', () {
    test('rests on the value it starts with', () {
      final tween = HlTween(4);
      expect(tween.valueAt(0), 4);
      expect(tween.valueAt(1e6), 4);
    });

    test('retargeting to the same value does nothing', () {
      final tween = HlTween(4)..retarget(9, 100, 0);
      final started = tween.startMs;
      tween.retarget(9, 500, 0);
      expect(tween.startMs, started);
    });

    test('moves toward its target and lands on it', () {
      final tween = HlTween(0, 400)..retarget(10, 1000, 0);
      expect(tween.valueAt(1000), 0);
      expect(tween.valueAt(1200), inExclusiveRange(0, 10));
      expect(tween.valueAt(1400), 10);
      expect(tween.valueAt(5000), 10);
    });

    test('a delay holds the start back', () {
      final tween = HlTween(0, 400)..retarget(10, 1000, 300);
      expect(tween.valueAt(1200), 0);
      expect(tween.valueAt(1400), greaterThan(0));
      expect(tween.doneAt(1400), isFalse);
      expect(tween.doneAt(1700), isTrue);
    });

    test('retargeting mid flight continues from where it is, with no jump', () {
      final tween = HlTween(0, 400)..retarget(10, 0, 0);
      final here = tween.valueAt(150);
      tween.retarget(-5, 150, 0);
      expect(tween.valueAt(150), closeTo(here, 1e-9));
      expect(tween.valueAt(2000), -5);
    });
  });
}
