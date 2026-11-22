import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/widgets/swipe_toast_logic.dart';

void main() {
  group('swipeAxisOf', () {
    test('tiny movement has no axis yet', () {
      expect(swipeAxisOf(const Offset(3, 2)), isNull);
    });

    test('picks the dominant axis', () {
      expect(swipeAxisOf(const Offset(20, 4)), SwipeAxis.horizontal);
      expect(swipeAxisOf(const Offset(-20, 4)), SwipeAxis.horizontal);
      expect(swipeAxisOf(const Offset(4, 20)), SwipeAxis.vertical);
      expect(swipeAxisOf(const Offset(4, -20)), SwipeAxis.vertical);
    });
  });

  group('swipeOffset', () {
    test(
      'horizontal follows the finger both ways and ignores the other axis',
      () {
        expect(
          swipeOffset(SwipeAxis.horizontal, const Offset(-50, 30)),
          const Offset(-50, 0),
        );
        expect(
          swipeOffset(SwipeAxis.horizontal, const Offset(50, -30)),
          const Offset(50, 0),
        );
      },
    );

    test('vertical follows down fully and resists going up', () {
      expect(
        swipeOffset(SwipeAxis.vertical, const Offset(9, 40)),
        const Offset(0, 40),
      );
      final up = swipeOffset(SwipeAxis.vertical, const Offset(0, -100));
      expect(up.dy, closeTo(-18, 0.001));
    });
  });

  group('swipeDistance', () {
    test('is absolute sideways and only downward vertically', () {
      expect(swipeDistance(SwipeAxis.horizontal, const Offset(-80, 0)), 80);
      expect(swipeDistance(SwipeAxis.vertical, const Offset(0, 60)), 60);
      expect(swipeDistance(SwipeAxis.vertical, const Offset(0, -20)), 0);
    });
  });

  group('swipeShouldClose', () {
    test('a long drag closes without needing speed', () {
      expect(swipeShouldClose(distance: 73, speed: 0), isTrue);
    });

    test('a short slow drag does not close', () {
      expect(swipeShouldClose(distance: 50, speed: 0.1), isFalse);
      expect(swipeShouldClose(distance: 72, speed: 0.1), isFalse);
    });

    test('a quick flick over a short distance closes', () {
      expect(swipeShouldClose(distance: 40, speed: 2), isTrue);
    });

    test('speed alone does not close if barely moved', () {
      expect(swipeShouldClose(distance: 10, speed: 5), isFalse);
    });
  });

  group('swipeFade', () {
    test('is opaque at rest and never fully transparent', () {
      expect(swipeFade(Offset.zero), 1);
      expect(swipeFade(const Offset(9999, 0)), 0.3);
    });

    test('fades as it travels', () {
      expect(swipeFade(const Offset(140, 0)), closeTo(0.5, 0.001));
    });
  });
}
