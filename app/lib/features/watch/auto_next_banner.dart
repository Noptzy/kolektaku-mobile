import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import 'auto_next.dart';

class AutoNextBanner extends StatelessWidget {
  const AutoNextBanner({
    super.key,
    required this.autoNext,
    required this.label,
  });

  final AutoNext autoNext;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: autoNext,
      builder: (context, child) {
        if (!autoNext.active) return const SizedBox.shrink();
        final theme = ShadTheme.of(context);
        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: DecoratedBox(
              key: const Key('auto-next'),
              decoration: BoxDecoration(
                color: theme.colorScheme.popover,
                borderRadius: Radii.cardShape,
                border: Border.all(color: theme.colorScheme.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: Spacing.sm,
                  children: [
                    Flexible(
                      child: Text(
                        '$label dalam ${autoNext.remaining} dtk',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.small,
                      ),
                    ),
                    ShadButton(
                      size: ShadButtonSize.sm,
                      key: const Key('auto-next-now'),
                      onPressed: autoNext.now,
                      child: const Text('Putar'),
                    ),
                    ShadButton.ghost(
                      key: const Key('auto-next-cancel'),
                      size: ShadButtonSize.sm,
                      onPressed: autoNext.cancel,
                      child: const Text('Batal'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
