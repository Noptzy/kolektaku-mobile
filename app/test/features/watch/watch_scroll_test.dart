import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/detail/episode_row.dart';
import 'package:kolektaku/features/watch/watch_details.dart';

void main() {
  group('scrollTargetFor', () {
    test('a row already on screen needs no scrolling', () {
      expect(
        scrollTargetFor(
          headerHeight: 300,
          index: 0,
          offset: 0,
          viewport: 547,
          maxExtent: 5000,
        ),
        isNull,
      );
    });

    test('a row far down is brought a quarter of the way from the top', () {
      final target = scrollTargetFor(
        headerHeight: 300,
        index: 100,
        offset: 0,
        viewport: 600,
        maxExtent: 20000,
      );
      expect(target, 300 + 100 * episodeRowHeight - 150);
    });

    test('a row above the viewport is brought back into view', () {
      final target = scrollTargetFor(
        headerHeight: 300,
        index: 2,
        offset: 2000,
        viewport: 600,
        maxExtent: 20000,
      );
      expect(target, isNotNull);
      expect(target! < 2000, isTrue);
    });

    test('the target never leaves the scrollable range', () {
      expect(
        scrollTargetFor(
          headerHeight: 300,
          index: 1000,
          offset: 0,
          viewport: 600,
          maxExtent: 800,
        ),
        800,
      );
      expect(
        scrollTargetFor(
          headerHeight: 0,
          index: 5,
          offset: 9000,
          viewport: 600,
          maxExtent: -1,
        ),
        0,
      );
    });

    test('a row partly hidden at the bottom is scrolled into view', () {
      final target = scrollTargetFor(
        headerHeight: 300,
        index: 3,
        offset: 0,
        viewport: 600,
        maxExtent: 20000,
      );
      expect(target, isNotNull);
    });
  });
}
