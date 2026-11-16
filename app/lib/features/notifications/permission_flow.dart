import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../platform/background_checks.dart';
import '../../platform/notifier.dart';
import '../../widgets/swipe_sheet.dart';
import 'notification_prefs.dart';

Future<bool?> showNotifyExplainer(BuildContext context) {
  return showSwipeSheet<bool>(
    context: context,
    builder: (sheetContext) => ShadSheet(
      title: const Text('Kabari kalau ada yang baru?'),
      description: const Text(
        'Kolektaku bisa memberi tahu saat favoritmu punya episode atau '
        'chapter baru. Android akan meminta izin notifikasi.',
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Spacing.sm,
          children: [
            ShadButton(
              key: const Key('notify-yes'),
              onPressed: () => Navigator.of(sheetContext).pop(true),
              child: const Text('Ya, kabari saya'),
            ),
            ShadButton.outline(
              key: const Key('notify-no'),
              onPressed: () => Navigator.of(sheetContext).pop(false),
              child: const Text('Nanti saja'),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> turnOnNotifications(Notifier notifier) async {
  await notifier.init();
  final granted = await notifier.requestPermission();
  await NotificationPrefs.setEnabled(granted);
  if (granted) await scheduleChecks(await NotificationPrefs.hours());
}

Future<void> askOnFirstFavorite(BuildContext context, Notifier notifier) async {
  if (await NotificationPrefs.asked()) return;
  await NotificationPrefs.markAsked();
  if (!context.mounted) return;
  final yes = await showNotifyExplainer(context);
  if (yes == true) await turnOnNotifications(notifier);
}
