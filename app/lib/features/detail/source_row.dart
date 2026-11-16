import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../widgets/pressable.dart';

class SourceRow extends StatelessWidget {
  const SourceRow({
    super.key,
    required this.canPick,
    required this.onPick,
    required this.onWrong,
  });

  final bool canPick;
  final VoidCallback onPick;
  final VoidCallback onWrong;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.screenGutter),
      child: Row(
        children: [
          Expanded(
            child: canPick
                ? Pressable(
                    onTap: onPick,
                    minSize: Sizes.touchTarget,
                    label: 'Ganti sumber',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            'Ganti sumber',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.small.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: Spacing.xs),
                        Icon(
                          LucideIcons.chevronDown,
                          size: 16,
                          color: theme.colorScheme.mutedForeground,
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          ShadButton.ghost(
            onPressed: onWrong,
            size: ShadButtonSize.sm,
            child: const Text('Bukan ini?'),
          ),
        ],
      ),
    );
  }
}
