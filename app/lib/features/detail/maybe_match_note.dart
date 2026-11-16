import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/sources.dart';
import 'maybe_match.dart';

class MaybeMatchNote extends StatelessWidget {
  const MaybeMatchNote({
    super.key,
    required this.link,
    required this.onYes,
    required this.onNo,
  });

  final SourceLinkDto link;
  final VoidCallback onYes;
  final VoidCallback onNo;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.screenGutter,
        0,
        Spacing.screenGutter,
        Spacing.md,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.card,
          borderRadius: BorderRadius.circular(Radii.card),
          border: Border.all(color: theme.colorScheme.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Column(
            key: const Key('maybe-match'),
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: Spacing.sm,
            children: [
              Text(
                'Mungkin ini?',
                style: theme.textTheme.large.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(maybeMatchLine(link), style: theme.textTheme.muted),
              Wrap(
                spacing: Spacing.sm,
                runSpacing: Spacing.sm,
                children: [
                  ShadButton(
                    key: const Key('maybe-match-yes'),
                    size: ShadButtonSize.sm,
                    onPressed: onYes,
                    child: const Text('Ya, ini'),
                  ),
                  ShadButton.outline(
                    key: const Key('maybe-match-no'),
                    size: ShadButtonSize.sm,
                    onPressed: onNo,
                    child: const Text('Bukan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
