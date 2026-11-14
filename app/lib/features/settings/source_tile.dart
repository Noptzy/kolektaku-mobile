import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_text.dart';
import '../../core/theme/kolektaku_tokens.dart';

class SourceTile extends StatelessWidget {
  const SourceTile({
    super.key,
    required this.label,
    required this.hint,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final bool enabled;
  final ValueChanged<bool> onChanged;

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
