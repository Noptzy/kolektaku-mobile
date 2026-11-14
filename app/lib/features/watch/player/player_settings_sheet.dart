import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/theme/kolektaku_tokens.dart';
import 'player_settings.dart';
import 'setting_row.dart';

class PlayerSettingsSheet extends StatefulWidget {
  const PlayerSettingsSheet({
    super.key,
    required this.choices,
    required this.close,
  });

  final List<SettingChoice> choices;
  final VoidCallback close;

  @override
  State<PlayerSettingsSheet> createState() => _PlayerSettingsSheetState();
}

class _PlayerSettingsSheetState extends State<PlayerSettingsSheet> {
  SettingChoice? _open;

  void _back() => setState(() => _open = null);

  @override
  Widget build(BuildContext context) {
    final open = _open;
    return PopScope(
      canPop: open == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _back();
      },
      child: ShadSheet(
        title: open == null
            ? const Text('Pengaturan pemutar')
            : _BackTitle(title: open.title, onBack: _back),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
          child: open == null ? _hub() : open.page(widget.close),
        ),
      ),
    );
  }

  Widget _hub() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final choice in widget.choices)
          SettingRow(
            choice: choice,
            onTap: () => setState(() => _open = choice),
          ),
      ],
    );
  }
}

class _BackTitle extends StatelessWidget {
  const _BackTitle({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: Spacing.sm,
      children: [
        ShadIconButton.ghost(
          key: const Key('player-settings-back'),
          icon: const Icon(LucideIcons.arrowLeft, size: 20),
          onPressed: onBack,
        ),
        Expanded(
          child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
