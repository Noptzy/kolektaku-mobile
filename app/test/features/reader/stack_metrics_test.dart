import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/reader/stack_metrics.dart';

const _width = 100.0;
const _page = _width / 0.7;

StackMetrics two() => StackMetrics()
  ..reset(3)
  ..append(2);

void main() {
  test('the second chapter starts after the first pages and the divider', () {
    final metrics = two();
    expect(metrics.topOf(0, _width), 0);
    expect(metrics.topOf(1, _width), 3 * _page + chapterDividerHeight);
  });

  test('an offset inside a page is found in its own chapter', () {
    final metrics = two();
    expect(metrics.locate(10, _width), (chapter: 0, page: 0));
    expect(metrics.locate(_page * 2 + 5, _width), (chapter: 0, page: 2));
    final second = metrics.topOf(1, _width);
    expect(metrics.locate(second + 5, _width), (chapter: 1, page: 0));
    expect(metrics.locate(second + _page + 5, _width), (chapter: 1, page: 1));
  });

  test('the divider belongs to the chapter it closes', () {
    final metrics = two();
    final dividerAt = 3 * _page + 20;
    expect(metrics.locate(dividerAt, _width).chapter, 0);
  });

  test('a known page shape moves everything below it', () {
    final metrics = two();
    final before = metrics.topOf(1, _width);
    expect(metrics.recordAspect(0, 0, 1.0), isTrue);
    expect(metrics.topOf(1, _width), lessThan(before));
    expect(metrics.recordAspect(0, 0, 1.0), isFalse);
  });

  test('past the end the last page of the last chapter is answered', () {
    final metrics = two();
    final far = metrics.totalHeight(_width) + 5000;
    expect(metrics.locate(far, _width), (chapter: 1, page: 1));
  });

  test('offsetOf points at the top of a page inside a chapter', () {
    final metrics = two();
    expect(metrics.offsetOf(1, 1, _width), metrics.topOf(1, _width) + _page);
  });

  test('reset forgets the older chapters', () {
    final metrics = two()..reset(4);
    expect(metrics.chapters, 1);
    expect(metrics.pagesOf(0), 4);
  });
}
