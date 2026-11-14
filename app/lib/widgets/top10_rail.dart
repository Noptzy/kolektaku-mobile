import 'package:flutter/widgets.dart';

import '../core/theme/kolektaku_tokens.dart';
import '../src/rust/dto/cards.dart';
import 'outlined_rank.dart';
import 'poster.dart';
import 'pressable.dart';
import 'rail.dart';
import 'score_badge.dart';

class Top10Rail extends StatelessWidget {
  const Top10Rail({
    super.key,
    required this.title,
    required this.cards,
    this.onTap,
    this.posterWidth = Sizes.railPosterWidth,
  });

  final String title;
  final List<MediaCardDto> cards;
  final ValueChanged<MediaCardDto>? onTap;
  final double posterWidth;

  @override
  Widget build(BuildContext context) {
    final ranked = cards.take(10).toList();
    return Rail(
      title: title,
      height: posterWidth / Sizes.posterAspect,
      itemCount: ranked.length,
      itemBuilder: (context, index) {
        final card = ranked[index];
        return _Entry(
          rank: index + 1,
          card: card,
          posterWidth: posterWidth,
          onTap: onTap == null ? null : () => onTap!(card),
        );
      },
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({
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
    final rankWidth = OutlinedRank.widthFor(rank);
    final overlap = rankWidth * 0.35;
    final score = card.score;
    return Pressable(
      onTap: onTap,
      label: 'Peringkat $rank, ${card.title}',
      child: SizedBox(
        width: rankWidth - overlap + posterWidth,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              bottom: 0,
              child: SizedBox(
                width: rankWidth,
                child: FittedBox(
                  alignment: Alignment.bottomLeft,
                  child: OutlinedRank(rank: rank),
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: posterWidth,
              child: Poster(
                url: card.coverUrl,
                overlays: [
                  if (score != null)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: ScoreBadge(score: score),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
