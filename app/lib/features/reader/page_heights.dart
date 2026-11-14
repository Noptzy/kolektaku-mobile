const fallbackPageAspect = 0.7;

class PageHeights {
  final Map<int, double> _aspects = {};

  bool record(int index, double aspect) {
    if (!aspect.isFinite || aspect <= 0) return false;
    final known = _aspects[index];
    if (known != null && (known - aspect).abs() < 0.0001) return false;
    _aspects[index] = aspect;
    return true;
  }

  double aspectOf(int index) => _aspects[index] ?? fallbackPageAspect;

  double heightOf(int index, double width) => width / aspectOf(index);

  double offsetOf(int index, double width) {
    var total = 0.0;
    for (var i = 0; i < index; i++) {
      total += heightOf(i, width);
    }
    return total;
  }

  double totalHeight(int count, double width) => offsetOf(count, width);

  int indexAt(double offset, double width, int count) {
    if (count <= 0) return 0;
    var bottom = 0.0;
    for (var i = 0; i < count; i++) {
      bottom += heightOf(i, width);
      if (bottom > offset) return i;
    }
    return count - 1;
  }
}
