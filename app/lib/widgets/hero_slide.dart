import '../core/genre_names.dart';
import '../src/rust/dto/cards.dart';

class HeroSlide {
  const HeroSlide({
    required this.title,
    required this.meta,
    this.imageUrl,
    this.synopsis,
    this.label,
    this.score,
    this.hasTrailer = false,
    this.actionLabel,
  });

  factory HeroSlide.fromCard(
    MediaCardDto card, {
    bool hasTrailer = false,
    String? actionLabel,
    String? label,
  }) {
    final parts = <String>[
      if (card.year != null) '${card.year}',
      if (card.format != null) card.format!,
      if (card.genres.isNotEmpty) genreLabel(card.genres.first),
    ];
    return HeroSlide(
      title: card.title,
      meta: parts.join(' · '),
      imageUrl: card.coverHdUrl ?? card.coverUrl,
      synopsis: card.synopsis,
      label: label,
      score: card.score,
      hasTrailer: hasTrailer,
      actionLabel: actionLabel,
    );
  }

  final String title;
  final String meta;
  final String? imageUrl;
  final String? synopsis;
  final String? label;
  final double? score;
  final bool hasTrailer;
  final String? actionLabel;
}
