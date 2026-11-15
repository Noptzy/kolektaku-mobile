import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../reader/read_failure.dart';

class NovelFailure extends StatelessWidget {
  const NovelFailure({
    super.key,
    required this.title,
    required this.error,
    required this.onBack,
    required this.onRetry,
    required this.onOtherSource,
  });

  final String title;
  final Object? error;
  final VoidCallback onBack;
  final VoidCallback onRetry;
  final VoidCallback onOtherSource;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Spacing.md,
          children: [
            Text(
              'Chapter tidak bisa dibuka',
              textAlign: TextAlign.center,
              style: theme.textTheme.large,
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.muted,
            ),
            Text(
              readFailureMessage(error),
              key: const Key('novel-failure-detail'),
              textAlign: TextAlign.center,
              style: theme.textTheme.muted,
            ),
            ShadButton(
              key: const Key('novel-retry'),
              onPressed: onRetry,
              child: const Text('Coba lagi'),
            ),
            ShadButton.outline(
              key: const Key('novel-other-source'),
              onPressed: onOtherSource,
              child: const Text('Coba sumber lain'),
            ),
            ShadButton.ghost(
              key: const Key('novel-failure-back'),
              onPressed: onBack,
              child: const Text('Kembali'),
            ),
          ],
        ),
      ),
    );
  }
}
