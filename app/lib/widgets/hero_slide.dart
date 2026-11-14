import '../core/genre_names.dart';
import '../src/rust/dto/cards.dart';

class HeroSlide {
  const HeroSlide({
    required this.title,
    required this.meta,
    this.imageUrl,
    this.score,
    this.hasTrailer = false,
    this.actionLabel,
  });

  factory HeroSlide.fromCard(
    MediaCardDto card, {
    bool hasTrailer = false,
    String? actionLabel,
  }) {
    final parts = <String>[
      if (card.year != null) '${card.year}',
      if (card.format != null) card.format!,
      if (card.genres.isNotEmpty) genreLabel(card.genres.first),
    ];
    return HeroSlide(
      title: card.title,
      meta: parts.join(' · '),
      imageUrl: card.coverUrl,
      score: card.score,
      hasTrailer: hasTrailer,
      actionLabel: actionLabel,
    );
  }

  final String title;
  final String meta;
  final String? imageUrl;
  final double? score;
  final bool hasTrailer;
  final String? actionLabel;
}
