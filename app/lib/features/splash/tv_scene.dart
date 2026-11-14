import 'dart:math' as math;

import 'package:flutter/widgets.dart';

const channelCount = 4;
const channelSeconds = 0.8;
const staticShare = 0.14;
const sceneLoopSeconds = channelCount * channelSeconds;

const _channels = [
  [Color(0xFF3B82F6), Color(0xFF1E1B4B)],
  [Color(0xFFEC4899), Color(0xFF4C1D95)],
  [Color(0xFF10B981), Color(0xFF064E3B)],
  [Color(0xFFF5B82E), Color(0xFF7C2D12)],
];

int channelAt(double seconds) =>
    (seconds / channelSeconds).floor() % channelCount;

double channelPhase(double seconds) =>
    (seconds % channelSeconds) / channelSeconds;

bool isSnowing(double seconds) => channelPhase(seconds) < staticShare;

List<Color> channelColors(int channel) => _channels[channel % channelCount];

Color glowOf(double seconds) => channelColors(channelAt(seconds)).first;

double antennaSwing(double seconds) => math.sin(seconds * 2 * math.pi / 1.6);

int noiseSeed(double seconds) => (seconds * 40).floor();

double noiseAt(int seed, int index) {
  var mixed = (seed * 374761393 + index * 668265263) & 0x7FFFFFFF;
  mixed = ((mixed ^ (mixed >> 13)) * 1274126177) & 0x7FFFFFFF;
  mixed = mixed ^ (mixed >> 16);
  return (mixed & 0xFFFF) / 0xFFFF;
}

class TvPainter extends CustomPainter {
  const TvPainter({required this.seconds});

  final double seconds;

  @override
  void paint(Canvas canvas, Size size) {
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.height * 0.14, size.width, size.height * 0.8),
      Radius.circular(size.width * 0.12),
    );
    _glow(canvas, body);
    _antennas(canvas, size);
    canvas.drawRRect(body, Paint()..color = const Color(0xFF2A2A33));
    canvas.drawRRect(
      body.deflate(size.width * 0.02),
      Paint()..color = const Color(0xFF1C1C23),
    );
    final screen = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.07,
        size.height * 0.22,
        size.width * 0.66,
        size.height * 0.64,
      ),
      Radius.circular(size.width * 0.06),
    );
    _screen(canvas, screen);
    _panel(canvas, size);
    _legs(canvas, size);
  }

  void _glow(Canvas canvas, RRect body) {
    final paint = Paint()
      ..color = glowOf(seconds).withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26);
    canvas.drawRRect(body.inflate(8), paint);
  }

  void _antennas(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8A8A96)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final base = Offset(size.width * 0.4, size.height * 0.15);
    final swing = antennaSwing(seconds) * size.width * 0.03;
    canvas.drawLine(
      base,
      Offset(size.width * 0.18 + swing, size.height * 0.01),
      paint,
    );
    canvas.drawLine(
      base,
      Offset(size.width * 0.62 - swing, size.height * 0.02),
      paint,
    );
  }

  void _screen(Canvas canvas, RRect screen) {
    canvas.save();
    canvas.clipRRect(screen);
    final colors = channelColors(channelAt(seconds));
    canvas.drawRect(
      screen.outerRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ).createShader(screen.outerRect),
    );
    final phase = channelPhase(seconds);
    final rect = screen.outerRect;
    canvas.drawCircle(
      Offset(
        rect.left + rect.width * (0.2 + 0.6 * phase),
        rect.top + rect.height * 0.38,
      ),
      rect.height * 0.2,
      Paint()..color = const Color(0x55FFFFFF),
    );
    _roll(canvas, rect);
    _scanlines(canvas, rect);
    if (isSnowing(seconds)) _snow(canvas, rect);
    canvas.restore();
  }

  void _roll(Canvas canvas, Rect rect) {
    final y = rect.top + rect.height * ((seconds * 0.5) % 1);
    canvas.drawRect(
      Rect.fromLTWH(rect.left, y, rect.width, rect.height * 0.12),
      Paint()..color = const Color(0x18FFFFFF),
    );
  }

  void _scanlines(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 1;
    for (var y = rect.top; y < rect.bottom; y += 3) {
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), paint);
    }
  }

  void _snow(Canvas canvas, Rect rect) {
    final seed = noiseSeed(seconds);
    for (var i = 0; i < 90; i++) {
      final shade = (noiseAt(seed, i * 3 + 2) * 255).round();
      canvas.drawRect(
        Rect.fromLTWH(
          rect.left + noiseAt(seed, i * 3) * rect.width,
          rect.top + noiseAt(seed, i * 3 + 1) * rect.height,
          rect.width * 0.09,
          2,
        ),
        Paint()..color = Color.fromARGB(200, shade, shade, shade),
      );
    }
  }

  void _panel(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF55555F);
    for (var i = 0; i < 2; i++) {
      canvas.drawCircle(
        Offset(size.width * 0.86, size.height * (0.36 + i * 0.2)),
        size.width * 0.045,
        paint,
      );
    }
    canvas.drawCircle(
      Offset(size.width * 0.86, size.height * 0.76),
      size.width * 0.02,
      Paint()..color = glowOf(seconds),
    );
  }

  void _legs(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF2A2A33);
    for (final x in [0.16, 0.7]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * x,
            size.height * 0.92,
            size.width * 0.14,
            size.height * 0.08,
          ),
          const Radius.circular(3),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(TvPainter old) => old.seconds != seconds;
}
