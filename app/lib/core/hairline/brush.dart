import 'dart:ui';

import 'package:flutter/painting.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

const hairlineWidth = 400.0;
const hairlineHeight = 320.0;

enum HlPen { mid, edge, hi, lo }

class HairlinePalette {
  const HairlinePalette({
    required this.plate,
    required this.hi,
    required this.edge,
    required this.mid,
    required this.lo,
  });

  factory HairlinePalette.of(ShadColorScheme scheme) => HairlinePalette(
    plate: scheme.background,
    hi: scheme.primary,
    edge: const Color(0xFF6A6C74),
    mid: const Color(0xFF4A4A52),
    lo: const Color(0xFF30303A),
  );

  final Color plate;
  final Color hi;
  final Color edge;
  final Color mid;
  final Color lo;

  Color of(HlPen pen) => switch (pen) {
    HlPen.mid => mid,
    HlPen.edge => edge,
    HlPen.hi => hi,
    HlPen.lo => lo,
  };
}

class HairlineBrush {
  HairlineBrush(this.canvas, this.palette, double scale)
    : _stroke = 1 / scale,
      _fill = Paint()
        ..style = PaintingStyle.fill
        ..color = palette.plate;

  final Canvas canvas;
  final HairlinePalette palette;
  final double _stroke;
  final Paint _fill;

  void plate(Path path, HlPen pen) {
    canvas.drawPath(path, _fill);
    line(path, pen);
  }

  void line(Path path, HlPen pen) {
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = palette.of(pen),
    );
  }
}

abstract class HairlineFigure {
  const HairlineFigure();

  double get restMs => 0;

  void paint(HairlineBrush brush, double nowMs);
}
