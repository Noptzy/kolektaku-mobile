import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/theme/kolektaku_color_scheme.dart';
import '../core/theme/kolektaku_text.dart';
import '../core/theme/kolektaku_tokens.dart';

class TagBadge extends StatelessWidget {
  const TagBadge({super.key, required this.label, this.dot = false});

  final String label;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Align(
      alignment: Alignment.bottomLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.scrim,
          borderRadius: Radii.chipShape,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dot) ...[
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.favorite,
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox.square(dimension: 6),
                ),
                const SizedBox(width: 5),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.badge.copyWith(
                    color: theme.colorScheme.foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
