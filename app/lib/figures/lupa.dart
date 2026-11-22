import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../core/hairline/brush.dart';
import '../core/hairline/iso.dart';
import '../core/hairline/iso_shapes.dart';
import '../core/hairline/motion.dart';

const _cards = 6;
const _w = 50.0;
const _h = 34.0;
const _gap = 12.0;
const _lean = -10.0;
const _lift = 7.0;
const _thickness = 1.3;
const _lensRadius = 13.0;
const _lensZ = 44.0;
const _centerX = _w / 2;
const _dwellMs = 520.0;
const _liftDelayMs = 420.0;
const _lensSamples = 28;
const hopOrder = [2, 5, 1, 4, 0, 3];

class _CardPaths {
  const _CardPaths(this.back, this.face, this.window, this.caption);

  final Path back;
  final Path face;
  final Path window;
  final Path caption;
}

class Lupa extends HairlineFigure {
  Lupa({this.hopMs = 1500}) {
    final cam = Cam(45, 0.5, 2.5);
    fitCam(
      cam,
      const [
        (-6, -8, -4),
        (_w + 6, -8, -4),
        (-6, (_cards - 1) * _gap + 8, -4),
        (_w + 6, (_cards - 1) * _gap + 8, -4),
        (_centerX + _lensRadius + 22, (_cards - 1) * _gap, _lensZ + 3),
        (_centerX, -4, _lensZ + 3),
      ],
      200,
      166,
    );
    _p = project(cam);
    _front = facing(cam);
    final (ring, inner) = ringPair(
      -6,
      -8,
      _w + 6,
      (_cards - 1) * _gap + 8,
      5,
      1.4,
    );
    _base = prism(_p, _front, ring, inner, -4, 0);
  }

  final double hopMs;
  late final Project _p;
  late final Facing _front;
  late final Prism _base;
  late final List<Offset> _shape = fillet(
    const [Offset(0, 0), Offset(_w, 0), Offset(_w, _h), Offset(0, _h)],
    const [2.6, 2.6, 2.6, 2.6],
  );
  late final List<Offset> _window = fillet(
    const [
      Offset(5, 13),
      Offset(_w - 5, 13),
      Offset(_w - 5, _h - 5),
      Offset(5, _h - 5),
    ],
    const [2, 2, 2, 2],
  );
  final List<HlTween> _rise = List.generate(_cards, (_) => HlTween(0));
  final List<_CardPaths?> _posed = List.filled(_cards, null);
  final List<double> _posedAt = List.filled(_cards, double.nan);
  late HlTween _loupe;
  int _step = -1;
  int _at = hopOrder.first;
  double _since = -1e9;

  int get loupeCard => _at;

  int? litCard(double nowMs) => nowMs - _since > _dwellMs ? _at : null;

  void _hop(int card, double nowMs) {
    _rise[_at].retarget(0, nowMs, 0);
    _at = card;
    _since = nowMs;
    _loupe.retarget(card * _gap + 4, nowMs, 0);
    _rise[card].retarget(_lift, nowMs, _liftDelayMs);
  }

  void _advance(double nowMs) {
    final step = (nowMs / hopMs).floor();
    if (_step < 0) {
      _step = step;
      _at = hopOrder[step % hopOrder.length];
      _loupe = HlTween(_at * _gap + 4);
      _rise[_at] = HlTween(_lift);
      return;
    }
    if (step == _step) return;
    _step = step;
    _hop(hopOrder[step % hopOrder.length], nowMs);
  }

  _CardPaths _pose(int card, double lift) {
    if (_posedAt[card] == lift) return _posed[card]!;
    final yb = card * _gap;
    final s = math.sin(radians(_lean));
    final c = math.cos(radians(_lean));
    Offset face(double u, double v) => _p(u, yb + v * s, v * c + lift);
    Offset back(double u, double v) =>
        _p(u, yb + v * s - _thickness * c, v * c + _thickness * s + lift);
    final paths = _CardPaths(
      polygon(_shape.map((q) => back(q.dx, q.dy))),
      polygon(_shape.map((q) => face(q.dx, q.dy))),
      polygon(_window.map((q) => face(q.dx, q.dy))),
      segment(face(6, 7), face(_w - 16, 7)),
    );
    _posedAt[card] = lift;
    return _posed[card] = paths;
  }

  Path _lens(double y, double radius) => polygon([
    for (var k = 0; k < _lensSamples; k++)
      _p(
        _centerX + radius * math.cos(k / _lensSamples * math.pi * 2),
        y + radius * math.sin(k / _lensSamples * math.pi * 2),
        _lensZ,
      ),
  ]);

  @override
  void paint(HairlineBrush brush, double nowMs) {
    _advance(nowMs);
    brush
      ..plate(_base.silhouette, HlPen.edge)
      ..line(_base.crease, HlPen.lo);
    final lit = litCard(nowMs);
    for (var i = 0; i < _cards; i++) {
      final lift = limitTo(_rise[i].valueAt(nowMs), 0, _lift);
      final card = _pose(i, lift);
      brush
        ..plate(card.back, HlPen.lo)
        ..plate(card.face, i == lit ? HlPen.hi : HlPen.edge)
        ..line(card.window, HlPen.lo)
        ..line(card.caption, HlPen.lo);
    }
    final y = _loupe.valueAt(nowMs);
    brush
      ..line(_lens(y, _lensRadius), HlPen.edge)
      ..line(_lens(y, _lensRadius - 2.6), HlPen.lo);
    final (handle, handleCrease) = ringPair(
      _centerX + _lensRadius - 1,
      y - 2.6,
      _centerX + _lensRadius + 22,
      y + 2.6,
      2.4,
      0.8,
    );
    final grip = prism(
      _p,
      _front,
      handle,
      handleCrease,
      _lensZ - 1.6,
      _lensZ + 1.6,
    );
    brush
      ..plate(grip.silhouette, HlPen.edge)
      ..line(grip.crease, HlPen.lo);
  }
}
