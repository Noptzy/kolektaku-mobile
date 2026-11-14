import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class StreamSpinner extends StatefulWidget {
  const StreamSpinner({super.key, this.size = 44});

  final double size;

  @override
  State<StreamSpinner> createState() => _StreamSpinnerState();
}

class _StreamSpinnerState extends State<StreamSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turns = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _turns.stop();
    } else if (!_turns.isAnimating) {
      _turns.repeat();
    }
  }

  @override
  void dispose() {
    _turns.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = ShadTheme.of(context).colorScheme.primary;
    return Semantics(
      label: 'Memuat',
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _turns,
          builder: (context, child) => CustomPaint(
            size: Size.square(widget.size),
            painter: SpinnerPainter(turn: _turns.value, color: color),
          ),
        ),
      ),
    );
  }
}

class SpinnerPainter extends CustomPainter {
  const SpinnerPainter({required this.turn, required this.color});

  final double turn;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.shortestSide / 11;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = color.withValues(alpha: 0.2);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke
      ..color = color;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);
    canvas.drawArc(rect, turn * math.pi * 2, math.pi * 1.2, false, arc);
  }

  @override
  bool shouldRepaint(SpinnerPainter old) =>
      old.turn != turn || old.color != color;
}
