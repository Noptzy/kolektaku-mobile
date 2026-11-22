import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/theme/kolektaku_tokens.dart';
import 'glass_surface.dart';
import 'pressable.dart';

class SwipeToastBody extends StatelessWidget {
  const SwipeToastBody({
    super.key,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return GlassSurface(
      radius: Radii.cardShape,
      child: Padding(
        padding: const EdgeInsets.only(left: Spacing.lg, right: Spacing.xs),
        child: Row(
          children: [
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.small.copyWith(
                  color: theme.colorScheme.foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Pressable(
              key: const Key('toast-action'),
              onTap: onAction,
              minSize: Sizes.touchTarget,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                child: Center(
                  child: Text(
                    actionLabel,
                    style: theme.textTheme.small.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
