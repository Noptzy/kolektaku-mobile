import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/theme/kolektaku_tokens.dart';
import '../features/watch/player/stream_spinner.dart';

class InfiniteFooter extends StatelessWidget {
  const InfiniteFooter({
    super.key,
    required this.hasMore,
    required this.loading,
    required this.onMore,
    this.failed = false,
    this.paused = false,
  });

  final bool hasMore;
  final bool loading;
  final bool failed;
  final bool paused;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(Spacing.xl),
        child: Center(child: StreamSpinner(size: 28)),
      );
    }
    if (hasMore && (failed || paused)) {
      return Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Center(
          child: ShadButton.outline(
            key: const Key('load-more'),
            onPressed: onMore,
            child: Text(failed ? 'Coba lagi' : 'Muat lagi'),
          ),
        ),
      );
    }
    return const SizedBox(height: Spacing.xl);
  }
}
