import 'package:flutter/widgets.dart' show ScrollMetrics;

import 'page_heights.dart';

const chapterDividerHeight = 280.0;
const _probeDepth = 0.3;

typedef StackSpot = ({int chapter, int page});

class StackMetrics {
  final List<PageHeights> _heights = [];
  final List<int> _counts = [];

  int get chapters => _counts.length;

  void reset(int pages) {
    _heights
      ..clear()
      ..add(PageHeights());
    _counts
      ..clear()
      ..add(pages);
  }

  void append(int pages) {
    _heights.add(PageHeights());
    _counts.add(pages);
  }

  PageHeights heightsOf(int chapter) => _heights[chapter];

  int pagesOf(int chapter) => _counts[chapter];

  double _extent(int chapter, double width) =>
      _heights[chapter].totalHeight(_counts[chapter], width) +
      chapterDividerHeight;

  double topOf(int chapter, double width) {
    var top = 0.0;
    for (var i = 0; i < chapter; i++) {
      top += _extent(i, width);
    }
    return top;
  }

  double offsetOf(int chapter, int page, double width) =>
      topOf(chapter, width) + _heights[chapter].offsetOf(page, width);

  double totalHeight(double width) => topOf(chapters, width);

  StackSpot spotAt(ScrollMetrics scroll, double width) {
    final probe = scroll.pixels + scroll.viewportDimension * _probeDepth;
    return locate(probe, width);
  }

  StackSpot locate(double offset, double width) {
    var top = 0.0;
    for (var i = 0; i < chapters; i++) {
      final extent = _extent(i, width);
      if (offset < top + extent || i == chapters - 1) {
        final inside = (offset - top).clamp(0, extent).toDouble();
        final page = _heights[i].indexAt(inside, width, _counts[i]);
        return (chapter: i, page: page);
      }
      top += extent;
    }
    return (chapter: 0, page: 0);
  }

  bool recordAspect(int chapter, int page, double aspect) =>
      _heights[chapter].record(page, aspect);
}
