import 'dart:io' show Platform;

import 'package:flutter/widgets.dart';

import '../../core/router.dart';
import '../../core/routes.dart';
import '../../platform/background_checks.dart';
import '../../platform/notifier.dart';
import 'notice_texts.dart';
import 'notification_prefs.dart';

void openFromPayload(String? payload) {
  final request = requestFromPayload(payload);
  if (request == null) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    kolektakuRouter.push(Routes.detail, extra: request);
  });
}

Future<void> setUpNotifications({Notifier? notifier}) async {
  if (notifier == null && !Platform.isAndroid) return;
  final shown = notifier ?? LocalNotifier();
  try {
    await shown.init(onTap: openFromPayload);
    final launched = await shown.launchPayload();
    if (launched != null) {
      Future<void>.delayed(
        const Duration(milliseconds: 800),
        () => openFromPayload(launched),
      );
    }
    if (await NotificationPrefs.enabled()) {
      await scheduleChecks(await NotificationPrefs.hours());
    }
  } on Object {
    debugPrint('notifications are not available');
  }
}
