import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_text.dart';
import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/library.dart';
import '../../widgets/poster.dart';
import '../../widgets/pressable.dart';
import 'collection_logic.dart';

const historyRowHeight = 92.0;

class HistoryRow extends StatelessWidget {
  const HistoryRow({
    super.key,
    required this.progress,
    required this.nowSecs,
    required this.onOpen,
    required this.onRemove,
  });

  final ProgressDto progress;
  final int nowSecs;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final muted = theme.colorScheme.mutedForeground;
    final fraction = historyFraction(progress);
    return SizedBox(
      height: historyRowHeight,
      child: Pressable(
        onTap: onOpen,
        label: progress.title,
        minSize: Sizes.touchTarget,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.xs,
          ),
          child: Row(
            spacing: Spacing.md,
            children: [
              SizedBox(
                width: 54,
                child: Poster(url: progress.coverUrl, radius: Radii.chip),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      progress.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.cardTitle,
                    ),
                    Text(
                      historyLine(progress),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.cardMeta.copyWith(color: muted),
                    ),
                    Text(
                      agoLabel(progress.updatedAtSecs, nowSecs),
                      maxLines: 1,
                      style: theme.textTheme.cardMeta.copyWith(color: muted),
                    ),
                    if (fraction != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: ShadProgress(value: fraction, minHeight: 3),
                      ),
                  ],
                ),
              ),
              ShadIconButton.ghost(
                key: Key('remove-history-${historyKey(progress)}'),
                icon: const Icon(LucideIcons.trash2, size: 18),
                onPressed: onRemove,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
