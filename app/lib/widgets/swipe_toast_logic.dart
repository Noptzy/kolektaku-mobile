import 'dart:math' as math;
import 'dart:ui' show Offset;

enum SwipeAxis { horizontal, vertical }

const swipeCloseDistance = 72.0;
const swipeFlingDistance = 24.0;
const swipeFlingSpeed = 0.5;
const swipeAxisSlop = 6.0;
const swipeUpResistance = 0.18;
const swipeFadeSpan = 280.0;
const swipeMinFade = 0.3;

SwipeAxis? swipeAxisOf(Offset delta) {
  if (delta.distance < swipeAxisSlop) return null;
  return delta.dx.abs() > delta.dy.abs()
      ? SwipeAxis.horizontal
      : SwipeAxis.vertical;
}

Offset swipeOffset(SwipeAxis axis, Offset delta) {
  if (axis == SwipeAxis.horizontal) return Offset(delta.dx, 0);
  return Offset(0, delta.dy > 0 ? delta.dy : delta.dy * swipeUpResistance);
}

double swipeDistance(SwipeAxis axis, Offset offset) {
  if (axis == SwipeAxis.horizontal) return offset.dx.abs();
  return math.max(0, offset.dy);
}

bool swipeShouldClose({required double distance, required double speed}) =>
    distance > swipeCloseDistance ||
    (distance > swipeFlingDistance && speed > swipeFlingSpeed);

double swipeFade(Offset offset) {
  final fade = 1 - offset.distance / swipeFadeSpan;
  return fade.clamp(swipeMinFade, 1.0);
}
