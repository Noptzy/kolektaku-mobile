import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';

Future<bool> confirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final agreed = await showShadSheet<bool>(
    context: context,
    side: ShadSheetSide.bottom,
    builder: (sheetContext) => ShadSheet(
      title: Text(title),
      description: Text(message),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.md),
        child: Row(
          spacing: Spacing.md,
          children: [
            Expanded(
              child: ShadButton.outline(
                key: const Key('confirm-cancel'),
                onPressed: () => Navigator.of(sheetContext).pop(false),
                child: const Flexible(
                  child: Text(
                    'Batal',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ShadButton.destructive(
                key: const Key('confirm-ok'),
                onPressed: () => Navigator.of(sheetContext).pop(true),
                child: Flexible(
                  child: Text(
                    confirmLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  return agreed ?? false;
}
