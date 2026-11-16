import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'clock_format.dart';

const seekBubbleWidth = 112.0;

class SeekBubble extends StatelessWidget {
  const SeekBubble({
    super.key,
    required this.target,
    required this.current,
    required this.thumbX,
    required this.trackWidth,
  });

  final Duration target;
  final Duration current;
  final double thumbX;
  final double trackWidth;

  String _delta() {
    final change = target - current;
    final sign = change.isNegative ? '-' : '+';
    return '$sign${formatClock(change.abs())}';
  }

  @override
  Widget build(BuildContext context) {
    final left = (thumbX - seekBubbleWidth / 2).clamp(
      0.0,
      (trackWidth - seekBubbleWidth).clamp(0.0, double.infinity),
    );
    final muted = ShadTheme.of(context).colorScheme.mutedForeground;
    return Positioned(
      left: left,
      top: -40,
      width: seekBubbleWidth,
      child: IgnorePointer(
        child: DecoratedBox(
          key: const Key('seek-bubble'),
          decoration: BoxDecoration(
            color: const Color(0xCC000000),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 6,
                children: [
                  Text(
                    formatClock(target),
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(_delta(), style: TextStyle(color: muted, fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
