import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/theme/kolektaku_text.dart';
import '../../../core/theme/kolektaku_tokens.dart';
import '../../../widgets/pressable.dart';
import '../../../widgets/swipe_sheet.dart';
import 'player_session.dart';
import 'player_settings.dart';

class PlayerSettingsButton extends StatelessWidget {
  const PlayerSettingsButton({
    super.key,
    required this.session,
    required this.onInteract,
    this.onAudio,
    this.audioLabel,
  });

  final PlayerSession session;
  final VoidCallback onInteract;
  final VoidCallback? onAudio;
  final String? audioLabel;

  @override
  Widget build(BuildContext context) {
    return ShadIconButton.ghost(
      key: const Key('player-settings'),
      icon: const Icon(LucideIcons.settings),
      onPressed: () {
        onInteract();
        final choices = settingChoices(
          context,
          session: session,
          onInteract: onInteract,
          onAudio: onAudio,
          audioLabel: audioLabel,
        );
        showSwipeSheet<void>(
          context: context,
          builder: (sheet) => ShadSheet(
            title: const Text('Pengaturan pemutar'),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final choice in choices)
                    SettingRow(
                      choice: choice,
                      onTap: () {
                        Navigator.of(sheet).pop();
                        choice.open();
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

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
            Icon(choice.icon, size: 20, color: muted),
            Expanded(child: Text(choice.label, style: theme.textTheme.p)),
            Flexible(
              child: Text(
                choice.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.cardMeta.copyWith(color: muted),
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 18, color: muted),
          ],
        ),
      ),
    );
  }
}
