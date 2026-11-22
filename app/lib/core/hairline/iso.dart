import 'dart:math' as math;
import 'dart:ui';

typedef Project = Offset Function(double x, double y, double z);
typedef Point3 = (double, double, double);

double radians(double degrees) => degrees * math.pi / 180;

double limitTo(double value, double low, double high) =>
    math.max(low, math.min(high, value));

class Cam {
  Cam(double azimuthDegrees, this.k, this.scale)
    : azimuth = radians(azimuthDegrees);

  final double azimuth;
  final double k;
  final double scale;
  double offsetX = 0;
  double offsetY = 0;
}

Project project(Cam cam) {
  final cosine = math.cos(cam.azimuth);
  final sine = math.sin(cam.azimuth);
  final lift = math.sqrt(1 - cam.k * cam.k);
  return (x, y, z) {
    final screenX = x * cosine - y * sine;
    final screenY = x * sine + y * cosine;
    return Offset(
      cam.offsetX + cam.scale * screenX,
      cam.offsetY + cam.scale * (screenY * cam.k - z * lift),
    );
  };
}

(double, double) unproject(Cam cam, double sx, double sy, double z) {
  final cosine = math.cos(cam.azimuth);
  final sine = math.sin(cam.azimuth);
  final lift = math.sqrt(1 - cam.k * cam.k);
  final screenX = (sx - cam.offsetX) / cam.scale;
  final screenY = ((sy - cam.offsetY) / cam.scale + z * lift) / cam.k;
  return (
    screenX * cosine + screenY * sine,
    -screenX * sine + screenY * cosine,
  );
}

void fitCam(Cam cam, List<Point3> points, double centerX, double centerY) {
  cam.offsetX = 0;
  cam.offsetY = 0;
  final p = project(cam);
  var left = double.infinity;
  var right = -double.infinity;
  var top = double.infinity;
  var bottom = -double.infinity;
  for (final (x, y, z) in points) {
    final q = p(x, y, z);
    left = math.min(left, q.dx);
    right = math.max(right, q.dx);
    top = math.min(top, q.dy);
    bottom = math.max(bottom, q.dy);
  }
  cam.offsetX = centerX - (left + right) / 2;
  cam.offsetY = centerY - (top + bottom) / 2;
}

Path polygon(Iterable<Offset> points) {
  final path = Path();
  var first = true;
  for (final point in points) {
    if (first) {
      path.moveTo(point.dx, point.dy);
      first = false;
    } else {
      path.lineTo(point.dx, point.dy);
    }
  }
  return path..close();
}

Path polyline(Iterable<Offset> points) {
  final path = Path();
  var first = true;
  for (final point in points) {
    if (first) {
      path.moveTo(point.dx, point.dy);
      first = false;
    } else {
      path.lineTo(point.dx, point.dy);
    }
  }
  return path;
}

Path segment(Offset from, Offset to) => Path()
  ..moveTo(from.dx, from.dy)
  ..lineTo(to.dx, to.dy);

List<Offset> fillet(List<Offset> points, List<double> radii, [int steps = 4]) {
  final count = points.length;
  final out = <Offset>[];
  for (var i = 0; i < count; i++) {
    final before = points[(i + count - 1) % count];
    final corner = points[i];
    final after = points[(i + 1) % count];
    final toBefore = (before - corner).distance;
    final toAfter = (after - corner).distance;
    final cut = math.min(radii[i], math.min(toBefore / 2, toAfter / 2));
    final start = corner + (before - corner) / toBefore * cut;
    final end = corner + (after - corner) / toAfter * cut;
    for (var k = 0; k <= steps; k++) {
      final s = k / steps;
      final w = 1 - s;
      out.add(start * (w * w) + corner * (2 * w * s) + end * (s * s));
    }
  }
  return out;
}
