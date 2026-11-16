import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_text.dart';
import '../../core/theme/kolektaku_tokens.dart';
import 'source_ping_labels.dart';

class SourceTile extends StatelessWidget {
  const SourceTile({
    super.key,
    required this.label,
    required this.hint,
    required this.enabled,
    required this.onChanged,
    this.ping,
    this.checking = false,
  });

  final String label;
  final String hint;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final PingReading? ping;
  final bool checking;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.screenGutter,
        vertical: Spacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(label, style: theme.textTheme.cardTitle),
                Text(
                  hint,
                  key: const Key('source-hint'),
                  style: theme.textTheme.cardMeta.copyWith(
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
                if (checking)
                  Text(
                    'Mengecek…',
                    key: const Key('source-ping'),
                    style: theme.textTheme.cardMeta.copyWith(
                      color: theme.colorScheme.mutedForeground,
                    ),
                  )
                else if (ping != null)
                  Text(
                    ping!.text,
                    key: const Key('source-ping'),
                    style: theme.textTheme.cardMeta.copyWith(
                      color: switch (ping!.tone) {
                        PingTone.good => theme.colorScheme.primary,
                        PingTone.warning => theme.colorScheme.mutedForeground,
                        PingTone.bad => theme.colorScheme.destructive,
                      },
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          ShadSwitch(
            key: const Key('source-switch'),
            value: enabled,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
