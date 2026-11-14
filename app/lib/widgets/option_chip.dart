import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/theme/kolektaku_tokens.dart';
import 'pressable.dart';

class OptionChip extends StatelessWidget {
  const OptionChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.trailing,
    this.dense = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? trailing;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final scheme = theme.colorScheme;
    final ink = selected ? scheme.primaryForeground : scheme.mutedForeground;
    return Pressable(
      onTap: onTap,
      selected: selected,
      label: label,
      minSize: 40,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.card,
          borderRadius: Radii.chipShape,
          border: Border.all(color: selected ? scheme.primary : scheme.border),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: dense ? Spacing.xs : Spacing.lg,
            vertical: Spacing.sm + 2,
          ),
          child: Row(
            mainAxisSize: dense ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: Spacing.sm,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: theme.textTheme.small.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (trailing != null) Icon(trailing, size: 14, color: ink),
            ],
          ),
        ),
      ),
    );
  }
}
