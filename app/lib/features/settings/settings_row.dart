import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_text.dart';
import '../../core/theme/kolektaku_tokens.dart';
import '../../widgets/pressable.dart';

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    required this.summary,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final scheme = theme.colorScheme;
    return Pressable(
      onTap: onTap,
      label: '$title, $summary',
      minSize: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.md,
        ),
        child: Row(
          spacing: Spacing.md,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SizedBox.square(
                dimension: 40,
                child: Icon(icon, size: 20, color: scheme.primary),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(title, style: theme.textTheme.cardTitle),
                  Text(
                    summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.cardMeta.copyWith(
                      color: scheme.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: scheme.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.screenGutter,
        Spacing.lg,
        Spacing.screenGutter,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Spacing.sm,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: Spacing.xs),
            child: Text(
              title,
              style: theme.textTheme.small.copyWith(
                color: scheme.mutedForeground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.card,
              borderRadius: Radii.cardShape,
              border: Border.all(color: scheme.border),
            ),
            child: ClipRRect(
              borderRadius: Radii.cardShape,
              child: Column(
                children: [
                  for (var index = 0; index < children.length; index++) ...[
                    if (index > 0)
                      Container(
                        height: 1,
                        margin: const EdgeInsets.only(left: 68),
                        color: scheme.border,
                      ),
                    children[index],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
