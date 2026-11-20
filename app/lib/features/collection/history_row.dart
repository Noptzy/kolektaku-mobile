import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/library.dart';
import '../../widgets/poster.dart';
import '../../widgets/pressable.dart';
import '../home/resume_card.dart';
import 'history_logic.dart';

const historyRowHeight = 76.0;
const _thumbWidth = 112.0;

class HistoryRow extends StatelessWidget {
  const HistoryRow({super.key, required this.item, required this.onTap});

  final ProgressDto item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final muted = theme.textTheme.muted.copyWith(fontSize: 12);
    final meta = resumeMeta(item.kind, item.unitNumber);
    return Pressable(
      onTap: onTap,
      label: '${item.title}, $meta, ${historyTimeLabel(item)}',
      child: SizedBox(
        height: historyRowHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
          child: Row(
            spacing: Spacing.md,
            children: [
              SizedBox(
                width: _thumbWidth,
                child: Poster(
                  url: item.coverUrl,
                  aspectRatio: 16 / 9,
                  radius: Radii.poster - 4,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.small.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(child: Text(meta, maxLines: 1, style: muted)),
                        Text(
                          historyTimeLabel(item),
                          key: const Key('history-time'),
                          style: muted.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.sm),
                    ShadProgress(value: historyProgress(item), minHeight: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
