import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class HoldBadge extends StatelessWidget {
  const HoldBadge({super.key, required this.shown});

  final bool shown;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, -0.7),
      child: IgnorePointer(
        child: AnimatedOpacity(
          key: const Key('hold-badge'),
          opacity: shown ? 1 : 0,
          duration: const Duration(milliseconds: 150),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xB3000000),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 6,
                children: [
                  Text(
                    '2x',
                    style: ShadTheme.of(context).textTheme.small.copyWith(
                      color: const Color(0xFFFFFFFF),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Icon(
                    LucideIcons.fastForward,
                    size: 16,
                    color: Color(0xFFFFFFFF),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
