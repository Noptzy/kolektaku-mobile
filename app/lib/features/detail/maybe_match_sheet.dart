import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/sources.dart';
import '../../widgets/swipe_sheet.dart';
import 'maybe_match.dart';

enum MaybeMatchAnswer { yes, no }

Future<MaybeMatchAnswer?> showMaybeMatchSheet(
  BuildContext context,
  SourceLinkDto link,
) {
  return showSwipeSheet<MaybeMatchAnswer>(
    context: context,
    builder: (sheetContext) => ShadSheet(
      title: const Text('Mungkin ini?'),
      description: Text(maybeMatchLine(link)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Spacing.sm,
          children: [
            ShadButton(
              key: const Key('maybe-sheet-yes'),
              onPressed: () =>
                  Navigator.of(sheetContext).pop(MaybeMatchAnswer.yes),
              child: const Text('Ya, ini'),
            ),
            ShadButton.outline(
              key: const Key('maybe-sheet-no'),
              onPressed: () =>
                  Navigator.of(sheetContext).pop(MaybeMatchAnswer.no),
              child: const Text('Bukan'),
            ),
          ],
        ),
      ),
    ),
  );
}
