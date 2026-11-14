import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../widgets/swipe_sheet.dart';
import 'player_session.dart';
import 'player_settings.dart';
import 'player_settings_sheet.dart';

class PlayerSettingsButton extends StatelessWidget {
  const PlayerSettingsButton({
    super.key,
    required this.session,
    required this.onInteract,
    this.audioPage,
    this.audioLabel,
  });

  final PlayerSession session;
  final VoidCallback onInteract;
  final SettingPage? audioPage;
  final String? audioLabel;

  @override
  Widget build(BuildContext context) {
    return ShadIconButton.ghost(
      key: const Key('player-settings'),
      icon: const Icon(LucideIcons.settings),
      onPressed: () {
        onInteract();
        final choices = settingChoices(
          session: session,
          onInteract: onInteract,
          audioPage: audioPage,
          audioLabel: audioLabel,
        );
        showSwipeSheet<void>(
          context: context,
          builder: (sheet) => PlayerSettingsSheet(
            choices: choices,
            close: () => Navigator.of(sheet).pop(),
          ),
        );
      },
    );
  }
}
