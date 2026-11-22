import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';

const _dot = 6.0;
const _activeWidth = 20.0;

class WelcomeDots extends StatelessWidget {
  const WelcomeDots({super.key, required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    final animate = !MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: 'Halaman ${index + 1} dari $count',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: Spacing.xs + 2,
          children: [
            for (var i = 0; i < count; i++)
              AnimatedContainer(
                key: Key('welcome-dot-$i'),
                duration: animate ? Motion.regular : Duration.zero,
                curve: const Cubic(0.23, 1, 0.32, 1),
                width: i == index ? _activeWidth : _dot,
                height: _dot,
                decoration: BoxDecoration(
                  color: i == index
                      ? scheme.primary
                      : scheme.foreground.withValues(alpha: 0.32),
                  borderRadius: BorderRadius.circular(_dot / 2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
