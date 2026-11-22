import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

const _slideDuration = Duration(milliseconds: 200);
const _slideCurve = Cubic(0.23, 1, 0.32, 1);
const _fillAlpha = 0.26;
const _ringAlpha = 0.36;
const _radius = 26.0;

class DockIndicator extends StatelessWidget {
  const DockIndicator({super.key, required this.index, required this.count});

  final int index;
  final int count;

  @override
  Widget build(BuildContext context) {
    final primary = ShadTheme.of(context).colorScheme.primary;
    final animate = !MediaQuery.disableAnimationsOf(context);
    return FractionallySizedBox(
      widthFactor: 1 / count,
      alignment: Alignment.centerLeft,
      child: AnimatedSlide(
        offset: Offset(index.toDouble(), 0),
        duration: animate ? _slideDuration : Duration.zero,
        curve: _slideCurve,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: primary.withValues(alpha: _fillAlpha),
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: primary.withValues(alpha: _ringAlpha)),
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
