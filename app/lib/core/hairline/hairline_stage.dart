import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'brush.dart';

const hairlineAspect = hairlineWidth / hairlineHeight;

class HairlineStage extends StatefulWidget {
  const HairlineStage({super.key, required this.create, this.height = 128});

  final HairlineFigure Function() create;
  final double height;

  @override
  State<HairlineStage> createState() => _HairlineStageState();
}

class _HairlineStageState extends State<HairlineStage>
    with SingleTickerProviderStateMixin {
  late final HairlineFigure _figure = widget.create();
  late final ValueNotifier<double> _now = ValueNotifier(_figure.restMs);
  late final Ticker _ticker = createTicker(
    (elapsed) => _now.value = elapsed.inMicroseconds / 1000,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _ticker.stop();
      _now.value = _figure.restMs;
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _now.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = HairlinePalette.of(ShadTheme.of(context).colorScheme);
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox(
          width: widget.height * hairlineAspect,
          height: widget.height,
          child: CustomPaint(painter: _StagePainter(_figure, palette, _now)),
        ),
      ),
    );
  }
}

class _StagePainter extends CustomPainter {
  _StagePainter(this.figure, this.palette, this.clock) : super(repaint: clock);

  final HairlineFigure figure;
  final HairlinePalette palette;
  final ValueNotifier<double> clock;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(
      size.width / hairlineWidth,
      size.height / hairlineHeight,
    );
    canvas
      ..save()
      ..translate(
        (size.width - hairlineWidth * scale) / 2,
        (size.height - hairlineHeight * scale) / 2,
      )
      ..scale(scale);
    figure.paint(HairlineBrush(canvas, palette, scale), clock.value);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StagePainter oldDelegate) =>
      oldDelegate.figure != figure || oldDelegate.palette != palette;
}
