import 'dart:math' as math;

import 'package:flutter/widgets.dart';

class DownloadRing extends StatelessWidget {
  const DownloadRing({
    super.key,
    required this.progress,
    required this.color,
    required this.track,
    this.thickness = 3,
    this.child,
  });

  final double progress;
  final Color color;
  final Color track;
  final double thickness;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: progress.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => CustomPaint(
        painter: RingPainter(
          progress: value,
          color: color,
          track: track,
          thickness: thickness,
        ),
        child: child,
      ),
      child: child,
    );
  }
}

class RingPainter extends CustomPainter {
  const RingPainter({
    required this.progress,
    required this.color,
    required this.track,
    required this.thickness,
  });

  final double progress;
  final Color color;
  final Color track;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inner = rect.deflate(thickness / 2);
    final base = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;
    canvas.drawArc(inner, 0, math.pi * 2, false, base);
    if (progress <= 0) return;
    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = thickness;
    canvas.drawArc(inner, -math.pi / 2, math.pi * 2 * progress, false, arc);
  }

  @override
  bool shouldRepaint(RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.track != track ||
      old.thickness != thickness;
}
