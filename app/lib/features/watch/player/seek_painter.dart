import 'package:flutter/widgets.dart';

typedef MarkSpan = (double start, double end);

const seekInset = 10.0;
const _trackHeight = 6.0;
const _thumbRadius = 7.0;
const _thumbActiveRadius = 10.0;

class SeekPainter extends CustomPainter {
  const SeekPainter({
    required this.fraction,
    required this.marks,
    required this.dragging,
    required this.trackColor,
    required this.playedColor,
    required this.markColor,
  });

  final double fraction;
  final List<MarkSpan> marks;
  final bool dragging;
  final Color trackColor;
  final Color playedColor;
  final Color markColor;

  RRect _bar(double left, double right, double middle) {
    return RRect.fromLTRBR(
      left,
      middle - _trackHeight / 2,
      right,
      middle + _trackHeight / 2,
      const Radius.circular(_trackHeight / 2),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final middle = size.height / 2;
    final width = size.width - seekInset * 2;
    final played = seekInset + width * fraction.clamp(0.0, 1.0);
    canvas.drawRRect(
      _bar(seekInset, seekInset + width, middle),
      Paint()..color = trackColor,
    );
    canvas.drawRRect(
      _bar(seekInset, played, middle),
      Paint()..color = playedColor,
    );
    final markPaint = Paint()..color = markColor;
    for (final mark in marks) {
      canvas.drawRRect(
        _bar(seekInset + width * mark.$1, seekInset + width * mark.$2, middle),
        markPaint,
      );
    }
    canvas.drawCircle(
      Offset(played, middle),
      dragging ? _thumbActiveRadius : _thumbRadius,
      Paint()..color = playedColor,
    );
  }

  @override
  bool shouldRepaint(SeekPainter old) =>
      old.fraction != fraction ||
      old.dragging != dragging ||
      old.marks != marks ||
      old.trackColor != trackColor ||
      old.playedColor != playedColor ||
      old.markColor != markColor;
}
