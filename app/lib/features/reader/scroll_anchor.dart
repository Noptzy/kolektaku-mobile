import 'package:flutter/widgets.dart';

import 'stack_metrics.dart';

class ScrollAnchor {
  ScrollAnchor({required this.metrics});

  final StackMetrics metrics;
  double _appliedZoom = 1;

  void followZoom(ScrollController scroll, double zoom, {double focalY = 0}) {
    if (zoom == _appliedZoom) return;
    if (scroll.hasClients) {
      final ratio = zoom / _appliedZoom;
      scroll.jumpTo((scroll.position.pixels + focalY) * ratio - focalY);
    }
    _appliedZoom = zoom;
  }

  void keepPlace({
    required ScrollController scroll,
    required double width,
    required int chapter,
    required int index,
    required double aspect,
    required bool above,
  }) {
    final heights = metrics.heightsOf(chapter);
    final before = heights.heightOf(index, width);
    if (!metrics.recordAspect(chapter, index, aspect)) return;
    final shift = heights.heightOf(index, width) - before;
    if (above && scroll.hasClients) {
      scroll.jumpTo(scroll.position.pixels + shift);
    }
  }
}
