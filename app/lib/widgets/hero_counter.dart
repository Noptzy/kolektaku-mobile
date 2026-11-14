import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/theme/kolektaku_text.dart';
import '../core/theme/kolektaku_tokens.dart';

class HeroCounter extends StatelessWidget {
  const HeroCounter({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.background.withValues(alpha: 0.55),
        borderRadius: Radii.chipShape,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm,
          vertical: Spacing.xs,
        ),
        child: Text(
          text,
          style: ShadTheme.of(context).textTheme.badge
              .copyWith(color: scheme.foreground),
        ),
      ),
    );
  }
}
