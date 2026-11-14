import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/theme/kolektaku_text.dart';
import '../../../core/theme/kolektaku_tokens.dart';
import '../../../widgets/pressable.dart';
import 'player_settings.dart';

class SettingRow extends StatelessWidget {
  const SettingRow({super.key, required this.choice, required this.onTap});

  final SettingChoice choice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final muted = theme.colorScheme.mutedForeground;
    return Pressable(
      key: Key('settings-row-${choice.id}'),
      onTap: onTap,
      label: '${choice.label}, ${choice.value}',
      minSize: Sizes.touchTarget,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
        child: Row(
          spacing: Spacing.md,
          children: [
            Icon(choice.icon, size: 18, color: muted),
            Text(
              choice.label,
              maxLines: 1,
              softWrap: false,
              style: theme.textTheme.small,
            ),
            Expanded(
              child: Text(
                choice.value,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: theme.textTheme.cardMeta.copyWith(color: muted),
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 16, color: muted),
          ],
        ),
      ),
    );
  }
}
