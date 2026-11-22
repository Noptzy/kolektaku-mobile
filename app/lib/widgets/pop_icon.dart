import 'dart:math' as math;

import 'package:flutter/widgets.dart';

const _popDuration = Duration(milliseconds: 220);
const _spinDuration = Duration(milliseconds: 480);
const _startScale = 0.86;
const _peakScale = 1.08;

class PopIcon extends StatefulWidget {
  const PopIcon({
    super.key,
    required this.icon,
    required this.color,
    required this.selected,
    this.spin = false,
    this.size = 22,
  });

  final IconData icon;
  final Color color;
  final bool selected;
  final bool spin;
  final double size;

  @override
  State<PopIcon> createState() => _PopIconState();
}

class _PopIconState extends State<PopIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: widget.spin ? _spinDuration : _popDuration,
    value: 1,
  );

  @override
  void didUpdateWidget(PopIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    final becameSelected = widget.selected && !oldWidget.selected;
    if (becameSelected && !MediaQuery.disableAnimationsOf(context)) {
      _motion.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  double _scale(double t) {
    if (t < 0.6) {
      return _startScale +
          (_peakScale - _startScale) * Curves.easeOut.transform(t / 0.6);
    }
    return _peakScale -
        (_peakScale - 1) * Curves.easeOut.transform((t - 0.6) / 0.4);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _motion,
      builder: (context, child) {
        final t = _motion.value;
        final double turns = widget.spin ? Curves.easeOutCubic.transform(t) : 0;
        return Transform.scale(
          scale: _scale(t),
          child: Transform.rotate(angle: turns * 2 * math.pi, child: child),
        );
      },
      child: Icon(widget.icon, size: widget.size, color: widget.color),
    );
  }
}
