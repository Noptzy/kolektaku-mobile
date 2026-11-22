import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/theme/kolektaku_text.dart';
import '../core/theme/kolektaku_tokens.dart';
import '../src/rust/dto/cards.dart';
import 'poster.dart';
import 'pressable.dart';
import 'rail.dart';
import 'rank_number.dart';
import 'score_meta.dart';

const _titleLines = 2;
const topTenCount = 10;

double top10Height(double posterWidth, TextScaler scaler) {
  final title = scaler.scale(_titleLines * 13 * 1.25).ceilToDouble();
  final meta = scaler.scale(12 * 1.3).ceilToDouble();
  return posterWidth / Sizes.posterAspect + Spacing.sm + title + 2 + meta + 1;
}

class Top10Rail extends StatelessWidget {
  const Top10Rail({
    super.key,
    required this.title,
    required this.cards,
    this.onTap,
    this.posterWidth = Sizes.railPosterWidth,
    this.trailing,
  });

  final String title;
  final List<MediaCardDto> cards;
  final ValueChanged<MediaCardDto>? onTap;
  final double posterWidth;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ranked = cards.take(topTenCount).toList();
    return Rail(
      title: title,
      height: top10Height(posterWidth, MediaQuery.textScalerOf(context)),
      trailing: trailing,
      itemCount: ranked.length,
      itemBuilder: (context, index) => Top10Entry(
        rank: index + 1,
        card: ranked[index],
        posterWidth: posterWidth,
        onTap: onTap == null ? null : () => onTap!(ranked[index]),
      ),
    );
  }
}

class Top10List extends StatelessWidget {
  const Top10List({
    super.key,
    required this.cards,
    this.onTap,
    this.posterWidth = Sizes.railPosterWidth,
  });

  final List<MediaCardDto> cards;
  final ValueChanged<MediaCardDto>? onTap;
  final double posterWidth;

  @override
  Widget build(BuildContext context) {
    final ranked = cards.take(topTenCount).toList();
    return SizedBox(
      height: top10Height(posterWidth, MediaQuery.textScalerOf(context)),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.screenGutter),
        itemCount: ranked.length,
        separatorBuilder: (context, index) => const SizedBox(width: Spacing.md),
        itemBuilder: (context, index) => Top10Entry(
          rank: index + 1,
          card: ranked[index],
          posterWidth: posterWidth,
          onTap: onTap == null ? null : () => onTap!(ranked[index]),
        ),
      ),
    );
  }
}

class Top10Entry extends StatelessWidget {
  const Top10Entry({
    super.key,
    required this.rank,
    required this.card,
    required this.posterWidth,
    required this.onTap,
  });

  final int rank;
  final MediaCardDto card;
  final double posterWidth;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final rankWidth = RankNumber.widthFor(rank);
    final overlap = rankWidth * 0.35;
    final score = card.score;
    return Pressable(
      onTap: onTap,
      label: 'Peringkat $rank, ${card.title}',
      child: SizedBox(
        width: rankWidth - overlap + posterWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: posterWidth / Sizes.posterAspect,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    bottom: 0,
                    child: SizedBox(
                      width: rankWidth,
                      child: FittedBox(
                        alignment: Alignment.bottomLeft,
                        child: RankNumber(rank: rank),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: posterWidth,
                    child: Poster(url: card.coverUrl),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Padding(
              padding: EdgeInsets.only(left: rankWidth - overlap),
              child: SizedBox(
                width: posterWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.title,
                      maxLines: _titleLines,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.cardTitle,
                    ),
                    if (score != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: ScoreMeta(score: score),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
