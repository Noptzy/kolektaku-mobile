import 'package:flutter/widgets.dart';

import '../core/theme/kolektaku_tokens.dart';
import '../src/rust/dto/cards.dart';
import 'media_card.dart';
import 'media_card_height.dart';
import 'media_card_skeleton.dart';

const _columns = 3;

SliverPadding _frame(Widget Function(double width) build) {
  return SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: Spacing.screenGutter),
    sliver: SliverLayoutBuilder(
      builder: (context, constraints) {
        final gaps = Spacing.md * (_columns - 1);
        final width = (constraints.crossAxisExtent - gaps) / _columns;
        return build(width);
      },
    ),
  );
}

SliverGridDelegate _delegate(double width, BuildContext context) {
  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: _columns,
    mainAxisSpacing: Spacing.lg,
    crossAxisSpacing: Spacing.md,
    mainAxisExtent: mediaCardHeight(width, MediaQuery.textScalerOf(context)),
  );
}

class MediaGridSliver extends StatelessWidget {
  const MediaGridSliver({
    super.key,
    required this.cards,
    this.onTap,
    this.unitLabel,
    this.progressOf,
    this.tagOf,
    this.onRemove,
  });

  final String? Function(MediaCardDto card)? tagOf;
  final ValueChanged<MediaCardDto>? onRemove;
  final List<MediaCardDto> cards;
  final ValueChanged<MediaCardDto>? onTap;
  final String? unitLabel;
  final double? Function(MediaCardDto card)? progressOf;

  @override
  Widget build(BuildContext context) {
    return _frame(
      (width) => SliverGrid(
        gridDelegate: _delegate(width, context),
        delegate: SliverChildBuilderDelegate(childCount: cards.length, (
          context,
          index,
        ) {
          final card = cards[index];
          return MediaCard(
            card: card,
            unitLabel: unitLabel,
            progress: progressOf?.call(card),
            tag: tagOf?.call(card),
            onRemove: onRemove == null ? null : () => onRemove!(card),
            onTap: onTap == null ? null : () => onTap!(card),
          );
        }),
      ),
    );
  }
}

class MediaGridSkeletonSliver extends StatelessWidget {
  const MediaGridSkeletonSliver({super.key, this.count = 9});

  final int count;

  @override
  Widget build(BuildContext context) {
    return _frame(
      (width) => SliverGrid(
        gridDelegate: _delegate(width, context),
        delegate: SliverChildBuilderDelegate(
          childCount: count,
          (context, index) => const MediaCardSkeleton(),
        ),
      ),
    );
  }
}
