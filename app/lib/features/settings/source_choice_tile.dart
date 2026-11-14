import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_text.dart';
import '../../core/theme/kolektaku_tokens.dart';
import '../../widgets/pressable.dart';

class SourceChoiceTile extends StatelessWidget {
  const SourceChoiceTile({
    super.key,
    required this.title,
    required this.summary,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String summary;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.screenGutter,
        vertical: Spacing.xs,
      ),
      child: Pressable(
        onTap: onTap,
        selected: selected,
        label: title,
        minSize: Sizes.touchTarget,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.card,
            borderRadius: Radii.cardShape,
            border: Border.all(
              color: selected ? scheme.primary : scheme.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(title, style: theme.textTheme.cardTitle),
                      if (summary.isNotEmpty)
                        Text(
                          summary,
                          style: theme.textTheme.cardMeta.copyWith(
                            color: scheme.mutedForeground,
                          ),
                        ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(
                    LucideIcons.circleCheck,
                    size: 22,
                    color: scheme.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
