import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'tap_gesture_logic.dart';

class SkipBurst {
  const SkipBurst({required this.zone, required this.seconds});

  final TapZone zone;
  final int seconds;
}

class SkipFeedback extends StatelessWidget {
  const SkipFeedback({super.key, required this.zone, required this.burst});

  final TapZone zone;
  final ValueListenable<SkipBurst?> burst;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SkipBurst?>(
      valueListenable: burst,
      builder: (context, current, child) {
        final mine = current != null && current.zone == zone;
        return AnimatedOpacity(
          opacity: mine ? 1 : 0,
          duration: const Duration(milliseconds: 150),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0x33FFFFFF),
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(zone == TapZone.forward ? 160 : 0),
                right: Radius.circular(zone == TapZone.back ? 160 : 0),
              ),
            ),
            child: Center(child: _label(context, current)),
          ),
        );
      },
    );
  }

  Widget _label(BuildContext context, SkipBurst? current) {
    final seconds = current?.seconds ?? 0;
    final forward = zone == TapZone.forward;
    final sign = forward ? '+' : '-';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          forward ? LucideIcons.chevronsRight : LucideIcons.chevronsLeft,
          color: const Color(0xFFFFFFFF),
          size: 28,
        ),
        Text(
          '$sign$seconds dtk',
          style: ShadTheme.of(context).textTheme.h4
              .copyWith(color: const Color(0xFFFFFFFF)),
        ),
      ],
    );
  }
}
