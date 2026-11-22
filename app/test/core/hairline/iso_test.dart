import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/hairline/iso.dart';
import 'package:kolektaku/core/hairline/iso_shapes.dart';

void main() {
  group('project', () {
    test('the origin stays on the offset', () {
      final p = project(Cam(45, 0.5, 1));
      expect(p(0, 0, 0), Offset.zero);
    });

    test('x runs down and to the right at the default camera', () {
      final p = project(Cam(45, 0.5, 1));
      final point = p(1, 0, 0);
      expect(point.dx, closeTo(math.cos(math.pi / 4), 1e-9));
      expect(point.dy, closeTo(math.sin(math.pi / 4) * 0.5, 1e-9));
    });

    test('z goes straight up the screen', () {
      final p = project(Cam(45, 0.5, 1));
      final point = p(0, 0, 1);
      expect(point.dx, closeTo(0, 1e-9));
      expect(point.dy, closeTo(-math.sqrt(0.75), 1e-9));
    });

    test('scale multiplies and the offset shifts', () {
      final cam = Cam(45, 0.5, 2)
        ..offsetX = 10
        ..offsetY = 20;
      final point = project(cam)(0, 0, 0);
      expect(point, const Offset(10, 20));
      expect(project(cam)(0, 0, 1).dy, closeTo(20 - 2 * math.sqrt(0.75), 1e-9));
    });
  });

  group('unproject', () {
    test('undoes project on the ground', () {
      final cam = Cam(45, 0.5, 2.5)
        ..offsetX = 30
        ..offsetY = 40;
      final screen = project(cam)(7, 11, 0);
      final (x, y) = unproject(cam, screen.dx, screen.dy, 0);
      expect(x, closeTo(7, 1e-9));
      expect(y, closeTo(11, 1e-9));
    });

    test('undoes project on a raised plane', () {
      final cam = Cam(30, 0.6, 1.7);
      final screen = project(cam)(-3, 9, 5);
      final (x, y) = unproject(cam, screen.dx, screen.dy, 5);
      expect(x, closeTo(-3, 1e-9));
      expect(y, closeTo(9, 1e-9));
    });
  });

  test('fitCam centres the box of points on the target', () {
    final cam = Cam(45, 0.5, 2);
    final points = <Point3>[(0, 0, 0), (40, 0, 0), (0, 30, 0), (40, 30, 20)];
    fitCam(cam, points, 200, 160);
    final p = project(cam);
    final screen = [for (final (x, y, z) in points) p(x, y, z)];
    final left = screen.map((q) => q.dx).reduce(math.min);
    final right = screen.map((q) => q.dx).reduce(math.max);
    final top = screen.map((q) => q.dy).reduce(math.min);
    final bottom = screen.map((q) => q.dy).reduce(math.max);
    expect((left + right) / 2, closeTo(200, 1e-9));
    expect((top + bottom) / 2, closeTo(160, 1e-9));
  });

  group('rings', () {
    test('a rounded rectangle has four corners of steps + 1 samples', () {
      expect(roundedRect(0, 0, 20, 10, 3), hasLength(20));
      expect(roundedRect(0, 0, 20, 10, 3, 6), hasLength(28));
    });

    test('every sample has a unit normal', () {
      for (final q in roundedRect(0, 0, 20, 10, 3)) {
        expect(math.sqrt(q.nu * q.nu + q.nv * q.nv), closeTo(1, 1e-9));
      }
    });

    test('too big a radius is cut to half the shorter side', () {
      final ring = roundedRect(0, 0, 10, 4, 100);
      final spanV =
          ring.map((q) => q.v).reduce(math.max) -
          ring.map((q) => q.v).reduce(math.min);
      expect(spanV, closeTo(4, 1e-9));
    });

    test('a circle has the radius and count asked for', () {
      final ring = circle(5, 24);
      expect(ring, hasLength(24));
      for (final q in ring) {
        expect(math.sqrt(q.u * q.u + q.v * q.v), closeTo(5, 1e-9));
      }
    });

    test('ringPair insets the crease and keeps a minimum corner', () {
      final (outer, inner) = ringPair(0, 0, 20, 10, 4, 1.5);
      final outerSpan = outer.map((q) => q.u).reduce(math.max);
      final innerSpan = inner.map((q) => q.u).reduce(math.max);
      expect(outerSpan - innerSpan, closeTo(1.5, 1e-9));
      final (_, tight) = ringPair(0, 0, 20, 10, 1, 5);
      expect(tight, isNotEmpty);
    });
  });

  group('hull', () {
    test('a square with an inner point keeps only the corners', () {
      final points = hull(const [
        Offset(0, 0),
        Offset(10, 0),
        Offset(10, 10),
        Offset(0, 10),
        Offset(5, 5),
      ]);
      expect(points, hasLength(4));
      expect(points, isNot(contains(const Offset(5, 5))));
    });

    test('points on one edge do not add vertices', () {
      final points = hull(const [
        Offset(0, 0),
        Offset(5, 0),
        Offset(10, 0),
        Offset(10, 10),
        Offset(0, 10),
      ]);
      expect(points, hasLength(4));
    });
  });

  group('facing and run', () {
    test('half of a circle faces the camera', () {
      final cam = Cam(45, 0.5, 1);
      final ring = circle(5, 48);
      final front = facing(cam);
      final facingCount = ring.where(front).length;
      expect(facingCount, inInclusiveRange(23, 26));
    });

    test('run returns one contiguous stretch', () {
      final cam = Cam(45, 0.5, 1);
      final ring = circle(5, 48);
      final front = facing(cam);
      final stretch = run(ring, front);
      expect(stretch, isNotEmpty);
      expect(stretch.every(front), isTrue);
      expect(stretch.length, lessThan(ring.length));
    });

    test(
      'run keeps everything when everything passes and nothing otherwise',
      () {
        final ring = circle(5, 12);
        expect(run(ring, (_) => true), hasLength(12));
        expect(run(ring, (_) => false), isEmpty);
      },
    );
  });

  group('prism', () {
    test('its silhouette covers both heights', () {
      final cam = Cam(45, 0.5, 2);
      final p = project(cam);
      final (outline, inner) = ringPair(0, 0, 20, 10, 3, 1);
      final shape = prism(p, facing(cam), outline, inner, 0, 8);
      final bounds = shape.silhouette.getBounds();
      final lowest = ringAt(p, outline, 0).map((q) => q.dy).reduce(math.max);
      final highest = ringAt(p, outline, 8).map((q) => q.dy).reduce(math.min);
      expect(bounds.bottom, closeTo(lowest, 1e-6));
      expect(bounds.top, closeTo(highest, 1e-6));
    });

    test('without an inner ring there is no crease', () {
      final cam = Cam(45, 0.5, 2);
      final shape = prism(
        project(cam),
        facing(cam),
        roundedRect(0, 0, 20, 10, 3),
        null,
        0,
        4,
      );
      expect(shape.crease.getBounds(), Rect.zero);
    });
  });

  group('fillet', () {
    const square = [Offset(0, 0), Offset(20, 0), Offset(20, 20), Offset(0, 20)];

    test('every vertex becomes steps + 1 points', () {
      expect(fillet(square, const [3, 3, 3, 3]), hasLength(20));
      expect(fillet(square, const [3, 3, 3, 3], 6), hasLength(28));
    });

    test('rounded points stay inside the original outline', () {
      for (final q in fillet(square, const [4, 4, 4, 4])) {
        expect(q.dx, inInclusiveRange(0, 20));
        expect(q.dy, inInclusiveRange(0, 20));
      }
    });

    test('a radius larger than half an edge is cut down', () {
      final points = fillet(square, const [500, 500, 500, 500]);
      for (final q in points) {
        expect(q.dx, inInclusiveRange(0, 20));
        expect(q.dy, inInclusiveRange(0, 20));
      }
    });
  });

  group('paths', () {
    test('a polygon is closed and bounded by its points', () {
      final path = polygon(const [Offset(0, 0), Offset(10, 0), Offset(5, 8)]);
      expect(path.getBounds(), const Rect.fromLTRB(0, 0, 10, 8));
    });

    test('a polyline and a segment are open paths', () {
      expect(
        polyline(const [Offset(0, 0), Offset(4, 0), Offset(4, 3)]).getBounds(),
        const Rect.fromLTRB(0, 0, 4, 3),
      );
      expect(
        segment(const Offset(1, 1), const Offset(5, 4)).getBounds(),
        const Rect.fromLTRB(1, 1, 5, 4),
      );
    });

    test('limitTo clamps both ways', () {
      expect(limitTo(5, 0, 3), 3);
      expect(limitTo(-5, 0, 3), 0);
      expect(limitTo(2, 0, 3), 2);
    });
  });
}
