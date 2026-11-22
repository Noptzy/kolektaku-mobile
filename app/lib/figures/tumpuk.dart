import 'dart:math' as math;

import '../core/hairline/brush.dart';
import '../core/hairline/iso.dart';
import '../core/hairline/iso_shapes.dart';
import '../core/hairline/motion.dart';

const _plates = 4;
const _width = 46.0;
const _depth = 34.0;
const _thickness = 4.0;
const _step = 7.0;
const _out = 54.0;
const _height = 3 * _step + 12;

class PlateRow {
  const PlateRow({
    required this.plate,
    required this.x,
    required this.z,
    required this.moving,
  });

  final int plate;
  final double x;
  final double z;
  final bool moving;
}

List<PlateRow> stackAt(double nowMs, double beatMs) {
  final turn = beatMs * 3;
  final cycle = (nowMs / turn).floor();
  final u = (nowMs - cycle * turn) / beatMs;
  final phase = math.min(2, u.floor());
  final e = easeLift(u - phase);
  final rows = <PlateRow>[];
  for (var k = 0; k < _plates; k++) {
    final level = (k - cycle) % _plates;
    if (level == 0) {
      final x = phase == 0
          ? _out * e
          : phase == 1
          ? _out
          : _out * (1 - e);
      final z = phase == 0
          ? 0.0
          : phase == 1
          ? _height * e
          : _height + (3 * _step - _height) * e;
      rows.add(PlateRow(plate: k, x: x, z: z, moving: true));
    } else {
      final drop = phase == 0
          ? 0.0
          : phase == 1
          ? _step * e
          : _step;
      rows.add(
        PlateRow(plate: k, x: 0, z: level * _step - drop, moving: false),
      );
    }
  }
  rows.sort((a, b) {
    final byHeight = a.z.compareTo(b.z);
    return byHeight != 0 ? byHeight : a.x.compareTo(b.x);
  });
  return rows;
}

class Tumpuk extends HairlineFigure {
  Tumpuk({this.beatMs = 700}) {
    final cam = Cam(45, 0.5, 2.75);
    fitCam(
      cam,
      const [
        (-6, -6, 0),
        (_width + _out + 6, _depth + 6, 0),
        (_width + _out + 6, -6, 0),
        (-6, _depth + 6, 0),
        (0, 0, _height + _thickness),
      ],
      200,
      168,
    );
    _p = project(cam);
    _front = facing(cam);
  }

  final double beatMs;
  late final Project _p;
  late final Facing _front;

  @override
  void paint(HairlineBrush brush, double nowMs) {
    for (final row in stackAt(nowMs, beatMs)) {
      final (outline, inner) = ringPair(
        row.x,
        0,
        row.x + _width,
        _depth,
        6,
        1.4,
      );
      final shape = prism(
        _p,
        _front,
        outline,
        inner,
        row.z,
        row.z + _thickness,
      );
      brush
        ..plate(shape.silhouette, row.moving ? HlPen.hi : HlPen.edge)
        ..line(shape.crease, HlPen.lo);
    }
  }
}
