import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class StatusPanel extends StatelessWidget {
  const StatusPanel({
    super.key,
    required this.message,
    this.detail,
    this.onRetry,
  });

  final String message;
  final String? detail;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ColoredBox(
      color: const Color(0xCC000000),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, style: theme.textTheme.large),
              if (detail != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    detail!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.muted,
                  ),
                ),
              if (onRetry != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: ShadButton(
                    key: const Key('retry'),
                    onPressed: onRetry,
                    child: const Text('Coba lagi'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class BufferingBadge extends StatelessWidget {
  const BufferingBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: ShadBadge.secondary(child: const Text('Memuat…')),
      ),
    );
  }
}
