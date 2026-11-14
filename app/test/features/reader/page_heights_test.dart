import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/reader/page_heights.dart';

void main() {
  group('PageHeights', () {
    test('an unmeasured page uses the typical manga aspect', () {
      final heights = PageHeights();
      expect(heights.aspectOf(0), fallbackPageAspect);
      expect(heights.heightOf(0, 700), closeTo(1000, 0.001));
    });

    test('a measured page is as tall as its own picture', () {
      final heights = PageHeights()..record(1, 2.0);
      expect(heights.heightOf(1, 600), 300);
      expect(heights.heightOf(0, 700), closeTo(1000, 0.001));
    });

    test('recording the same aspect again changes nothing', () {
      final heights = PageHeights();
      expect(heights.record(0, 0.5), isTrue);
      expect(heights.record(0, 0.5), isFalse);
      expect(heights.record(0, 0.6), isTrue);
    });

    test('nonsense aspects are ignored', () {
      final heights = PageHeights();
      expect(heights.record(0, 0), isFalse);
      expect(heights.record(0, -1), isFalse);
      expect(heights.record(0, double.nan), isFalse);
      expect(heights.record(0, double.infinity), isFalse);
      expect(heights.aspectOf(0), fallbackPageAspect);
    });

    test('an offset is the sum of the pages before it', () {
      final heights = PageHeights()
        ..record(0, 1.0)
        ..record(1, 0.5);
      expect(heights.offsetOf(0, 100), 0);
      expect(heights.offsetOf(1, 100), 100);
      expect(heights.offsetOf(2, 100), 300);
    });

    test('the total height counts every page', () {
      final heights = PageHeights()
        ..record(0, 1.0)
        ..record(1, 1.0);
      expect(heights.totalHeight(2, 100), 200);
    });

    test('the page under a position is found by walking the heights', () {
      final heights = PageHeights()
        ..record(0, 1.0)
        ..record(1, 1.0)
        ..record(2, 1.0);
      expect(heights.indexAt(0, 100, 3), 0);
      expect(heights.indexAt(99, 100, 3), 0);
      expect(heights.indexAt(100, 100, 3), 1);
      expect(heights.indexAt(250, 100, 3), 2);
    });

    test('a position past the end stays on the last page', () {
      final heights = PageHeights()..record(0, 1.0);
      expect(heights.indexAt(9999, 100, 1), 0);
      expect(heights.indexAt(9999, 100, 4), 3);
    });

    test('no pages means page zero', () {
      expect(PageHeights().indexAt(50, 100, 0), 0);
    });
  });
}
