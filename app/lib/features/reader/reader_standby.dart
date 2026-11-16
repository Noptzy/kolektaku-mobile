import 'package:flutter/widgets.dart';

import '../watch/player/standby_panel.dart';
import 'read_failure.dart';

Widget readerStandby({
  required String title,
  required String? coverUrl,
  required VoidCallback onBack,
  required Object? error,
  required VoidCallback onRetry,
}) {
  final failed = error != null;
  return StandbyPanel(
    title: title,
    imageUrl: coverUrl,
    onBack: onBack,
    message: failed ? 'Chapter tidak bisa dibuka' : 'Menyiapkan chapter…',
    detail: failed ? readFailureMessage(error) : null,
    onRetry: failed ? onRetry : null,
  );
}
