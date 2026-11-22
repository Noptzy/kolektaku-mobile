import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../core/hairline/brush.dart';
import '../core/hairline/iso.dart';
import '../core/hairline/iso_shapes.dart';

const _reelRadius = 34.0;
const _packRadius = 27.0;
const _hubRadius = 7.0;
const _baseZ = 3.0;
const _packZ = 5.0;
const _flangeZ = 17.0;
const _topZ = 19.2;
const _holeRing = 19.5;
const _holeRadius = 5.6;
const _holeCount = 5;
const _holeSteps = 16;
const _startTurn = 0.4;

class Gulungan extends HairlineFigure {
  Gulungan({this.rate = 1.2}) {
    final cam = Cam(45, 0.5, 2.1);
    fitCam(
      cam,
      const [
        (-48, -48, -4),
        (48, 48, -4),
        (48, -48, -4),
        (-48, 48, -4),
        (0, 0, _topZ + 3),
      ],
      200,
      168,
    );
    _p = project(cam);
    final front = facing(cam);
    final (plinth, plinthCrease) = ringPair(-48, -48, 48, 48, 12, 1.8);
    Prism reel(double radius, double z0, double z1, [double crease = 1.6]) =>
        prism(
          _p,
          front,
          circle(radius, 48),
          circle(radius - crease, 48),
          z0,
          z1,
        );
    _under = [
      prism(_p, front, plinth, plinthCrease, -4, 0),
      reel(_reelRadius, _baseZ, _packZ),
      reel(_packRadius, _packZ, _flangeZ, 1.4),
    ];
    final pack = run(circle(_packRadius, 48), front);
    _layers = Path()
      ..addPath(polyline(ringAt(_p, pack, 8.5)), Offset.zero)
      ..addPath(polyline(ringAt(_p, pack, 12.5)), Offset.zero);
    _over = [
      reel(_reelRadius, _flangeZ, _topZ),
      prism(
        _p,
        front,
        circle(_hubRadius, 24),
        circle(_hubRadius - 1.3, 24),
        _topZ,
        _topZ + 2,
      ),
    ];
  }

  final double rate;
  late final Project _p;
  late final List<Prism> _under;
  late final Path _layers;
  late final List<Prism> _over;
  double _turn = _startTurn;
  double? _lastMs;

  double get turn => _turn;

  void _solid(HairlineBrush brush, Prism shape) {
    brush
      ..plate(shape.silhouette, HlPen.edge)
      ..line(shape.crease, HlPen.lo);
  }

  Path _hole(double angle) {
    final cx = _holeRing * math.cos(angle);
    final cy = _holeRing * math.sin(angle);
    return polygon([
      for (var j = 0; j < _holeSteps; j++)
        _p(
          cx + _holeRadius * math.cos(j / _holeSteps * math.pi * 2),
          cy + _holeRadius * math.sin(j / _holeSteps * math.pi * 2),
          _topZ,
        ),
    ]);
  }

  @override
  void paint(HairlineBrush brush, double nowMs) {
    final last = _lastMs;
    _lastMs = nowMs;
    if (last != null && nowMs > last) _turn += rate * (nowMs - last) / 1000;
    for (final shape in _under) {
      _solid(brush, shape);
    }
    brush.line(_layers, HlPen.lo);
    _solid(brush, _over.first);
    final sway = _turn + 0.3 * math.sin(nowMs / 1100);
    for (var k = 0; k < _holeCount; k++) {
      brush.plate(
        _hole(sway + k * math.pi * 2 / _holeCount),
        k == 0 ? HlPen.hi : HlPen.edge,
      );
    }
    _solid(brush, _over.last);
  }
}
