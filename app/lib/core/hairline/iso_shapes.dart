import 'dart:math' as math;
import 'dart:ui';

import 'iso.dart';

class RingPoint {
  const RingPoint(this.u, this.v, this.nu, this.nv);

  final double u;
  final double v;
  final double nu;
  final double nv;
}

typedef Ring = List<RingPoint>;
typedef Facing = bool Function(RingPoint sample);

class Prism {
  const Prism(this.silhouette, this.crease);

  final Path silhouette;
  final Path crease;
}

Ring roundedRect(
  double u0,
  double v0,
  double u1,
  double v1,
  double radius, [
  int steps = 4,
]) {
  final r = math.max(
    0.0,
    math.min(radius, math.min((u1 - u0) / 2, (v1 - v0) / 2)),
  );
  final corners = [
    (u1 - r, v1 - r, 0.0),
    (u0 + r, v1 - r, 90.0),
    (u0 + r, v0 + r, 180.0),
    (u1 - r, v0 + r, 270.0),
  ];
  final out = <RingPoint>[];
  for (final (cu, cv, start) in corners) {
    for (var k = 0; k <= steps; k++) {
      final a = radians(start + 90 * k / steps);
      final ca = math.cos(a);
      final sa = math.sin(a);
      out.add(RingPoint(cu + r * ca, cv + r * sa, ca, sa));
    }
  }
  return out;
}

Ring circle(double radius, [int count = 96]) {
  return [
    for (var k = 0; k < count; k++)
      RingPoint(
        radius * math.cos(k / count * math.pi * 2),
        radius * math.sin(k / count * math.pi * 2),
        math.cos(k / count * math.pi * 2),
        math.sin(k / count * math.pi * 2),
      ),
  ];
}

(Ring, Ring) ringPair(
  double x0,
  double y0,
  double x1,
  double y1,
  double radius,
  double inset,
) => (
  roundedRect(x0, y0, x1, y1, radius),
  roundedRect(
    x0 + inset,
    y0 + inset,
    x1 - inset,
    y1 - inset,
    math.max(0.3, radius - inset),
  ),
);

List<Offset> ringAt(Project p, Ring ring, double z) => [
  for (final q in ring) p(q.u, q.v, z),
];

Facing facing(Cam cam) {
  final sine = math.sin(cam.azimuth);
  final cosine = math.cos(cam.azimuth);
  return (q) => q.nu * sine + q.nv * cosine >= -1e-6;
}

Ring run(Ring ring, Facing keep) {
  final count = ring.length;
  var start = -1;
  for (var i = 0; i < count; i++) {
    if (keep(ring[i]) && !keep(ring[(i + count - 1) % count])) {
      start = i;
      break;
    }
  }
  if (start < 0) return keep(ring[0]) ? ring.toList() : const [];
  final out = <RingPoint>[];
  for (var k = 0; k < count && keep(ring[(start + k) % count]); k++) {
    out.add(ring[(start + k) % count]);
  }
  return out;
}

List<Offset> hull(List<Offset> input) {
  final points = input.toList()
    ..sort(
      (a, b) => a.dx != b.dx ? a.dx.compareTo(b.dx) : a.dy.compareTo(b.dy),
    );
  double cross(Offset o, Offset a, Offset b) =>
      (a.dx - o.dx) * (b.dy - o.dy) - (a.dy - o.dy) * (b.dx - o.dx);
  final lower = <Offset>[];
  final upper = <Offset>[];
  for (final p in points) {
    while (lower.length > 1 &&
        cross(lower[lower.length - 2], lower.last, p) <= 0) {
      lower.removeLast();
    }
    lower.add(p);
  }
  for (final p in points.reversed) {
    while (upper.length > 1 &&
        cross(upper[upper.length - 2], upper.last, p) <= 0) {
      upper.removeLast();
    }
    upper.add(p);
  }
  lower.removeLast();
  upper.removeLast();
  return [...lower, ...upper];
}

Prism prism(
  Project p,
  Facing front,
  Ring outline,
  Ring? inner,
  double z0,
  double z1,
) {
  final silhouette = polygon(
    hull([...ringAt(p, outline, z1), ...ringAt(p, outline, z0)]),
  );
  final crease = inner == null
      ? Path()
      : polyline(ringAt(p, run(inner, front), z1));
  return Prism(silhouette, crease);
}
