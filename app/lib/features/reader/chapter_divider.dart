import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/sources.dart';
import '../detail/episode_info_map.dart';
import 'reader_controller.dart';
import 'stack_metrics.dart';

class ChapterDivider extends StatelessWidget {
  const ChapterDivider({
    super.key,
    required this.current,
    required this.next,
    required this.kind,
    required this.onContinue,
    required this.onRetry,
  });

  final double current;
  final UnitDto? next;
  final DividerKind kind;
  final VoidCallback onContinue;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final target = next == null ? '' : 'Chapter ${numberBadge(next!.number)}';
    return SizedBox(
      height: chapterDividerHeight,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: Spacing.md,
              children: [
                Text(
                  'Chapter ${numberBadge(current)} selesai',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.large,
                ),
                ..._below(theme, target),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _below(ShadThemeData theme, String target) {
    return switch (kind) {
      DividerKind.followed => [
        Text('Berikutnya: $target', style: theme.textTheme.muted),
        Icon(
          LucideIcons.arrowDown,
          size: 18,
          color: theme.colorScheme.mutedForeground,
        ),
      ],
      DividerKind.loading => [
        Text(
          'Menyiapkan $target…',
          key: const Key('divider-loading'),
          style: theme.textTheme.muted,
        ),
      ],
      DividerKind.failed => [
        Text('$target belum bisa dimuat.', style: theme.textTheme.muted),
        ShadButton.outline(
          key: const Key('divider-retry'),
          onPressed: onRetry,
          child: const Text('Coba lagi'),
        ),
      ],
      DividerKind.askToContinue => [
        ShadButton(
          key: const Key('end-next'),
          onPressed: onContinue,
          trailing: const Icon(LucideIcons.arrowRight, size: 16),
          child: Flexible(
            child: Text(
              'Lanjut ke $target',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      DividerKind.last => [
        Text('Ini chapter terakhir.', style: theme.textTheme.muted),
      ],
    };
  }
}
