import 'iso.dart';

typedef Easing = double Function(double t);

const _defaultTweenMs = 700.0;

Easing cubicBezier(double x1, double y1, double x2, double y2) {
  final cx = 3 * x1;
  final bx = 3 * (x2 - x1) - cx;
  final ax = 1 - cx - bx;
  final cy = 3 * y1;
  final by = 3 * (y2 - y1) - cy;
  final ay = 1 - cy - by;
  double x(double u) => ((ax * u + bx) * u + cx) * u;
  double y(double u) => ((ay * u + by) * u + cy) * u;
  double dx(double u) => (3 * ax * u + 2 * bx) * u + cx;
  return (t) {
    if (t <= 0) return 0;
    if (t >= 1) return 1;
    var u = t;
    for (var i = 0; i < 8; i++) {
      final error = x(u) - t;
      if (error.abs() < 1e-5) break;
      final slope = dx(u);
      if (slope.abs() < 1e-6) break;
      u -= error / slope;
    }
    if (!(u >= 0 && u <= 1) || (x(u) - t).abs() > 1e-4) {
      var low = 0.0;
      var high = 1.0;
      u = t;
      for (var i = 0; i < 24; i++) {
        if (x(u) < t) {
          low = u;
        } else {
          high = u;
        }
        u = (low + high) / 2;
      }
    }
    return y(u);
  };
}

final Easing easeLift = cubicBezier(0.32, 0.72, 0, 1);

class HlTween {
  HlTween(double value, [this.durationMs = _defaultTweenMs])
    : from = value,
      to = value,
      startMs = -1e9;

  double from;
  double to;
  double startMs;
  final double durationMs;

  double valueAt(double nowMs) {
    final progress = limitTo((nowMs - startMs) / durationMs, 0, 1);
    return from + (to - from) * easeLift(progress);
  }

  void retarget(double target, double nowMs, double delayMs) {
    if (to == target) return;
    from = valueAt(nowMs);
    to = target;
    startMs = nowMs + delayMs;
  }

  bool doneAt(double nowMs) => nowMs >= startMs + durationMs;
}
