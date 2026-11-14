import 'package:flutter/widgets.dart';

import '../core/pesan_error.dart';
import '../src/rust/error.dart';
import 'state_view.dart';

class ErrorStateView extends StatelessWidget {
  const ErrorStateView({super.key, required this.error, this.onRetry});

  final BridgeError error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final retry = canRetry(error) ? onRetry : null;
    if (isOffline(error)) return StateView.offline(onAction: retry);
    return StateView.error(
      title: 'Ada yang tidak beres',
      message: pesanError(error),
      actionLabel: retry == null ? null : 'Coba lagi',
      onAction: retry,
    );
  }
}
