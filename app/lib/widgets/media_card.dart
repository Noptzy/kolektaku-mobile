import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/theme/kolektaku_text.dart';
import '../core/theme/kolektaku_tokens.dart';
import '../src/rust/dto/cards.dart';
import 'limited_data_label.dart';
import 'media_meta.dart';
import 'new_badge.dart';
import 'poster.dart';
import 'pressable.dart';
import 'remove_dot.dart';
import 'score_badge.dart';
import 'tag_badge.dart';

class MediaCard extends StatelessWidget {
  const MediaCard({
    super.key,
    required this.card,
    this.onTap,
    this.progress,
    this.isNew = false,
    this.unitLabel = 'eps',
    this.tag,
    this.onRemove,
  });

  final MediaCardDto card;
  final VoidCallback? onTap;
  final double? progress;
  final bool isNew;
  final String unitLabel;
  final String? tag;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final meta = mediaMeta(card, unitLabel: unitLabel);
    return Pressable(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Poster(url: card.coverUrl, overlays: _overlays()),
          const SizedBox(height: Spacing.sm),
          Text(
            card.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.cardTitle,
          ),
          if (meta.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.cardMeta.copyWith(
                  color: theme.colorScheme.mutedForeground,
                ),
              ),
            ),
          if (card.limited)
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: LimitedDataLabel(),
            ),
        ],
      ),
    );
  }

  List<Widget> _overlays() {
    final score = card.score;
    final fraction = progress;
    return [
      if (isNew) const Positioned(top: 6, left: 6, child: NewBadge()),
      if (tag != null)
        Positioned(left: 6, bottom: 6, right: 6, child: TagBadge(label: tag!)),
      if (score != null)
        Positioned(top: 6, right: 6, child: ScoreBadge(score: score)),
      if (onRemove != null)
        Positioned(
          top: 2,
          right: 2,
          child: RemoveDot(key: const Key('remove-card'), onTap: onRemove!),
        ),
      if (fraction != null)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: ShadProgress(
            value: fraction.clamp(0.0, 1.0),
            minHeight: 3,
            borderRadius: BorderRadius.zero,
            innerBorderRadius: BorderRadius.zero,
          ),
        ),
    ];
  }
}
