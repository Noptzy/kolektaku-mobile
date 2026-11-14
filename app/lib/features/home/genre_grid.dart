import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/genre_names.dart';
import '../../core/theme/kolektaku_text.dart';
import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/cards.dart';
import '../../src/rust/dto/sources.dart';
import '../../widgets/genre_card.dart';
import 'genre_cover.dart';

class GenreGrid extends StatelessWidget {
  const GenreGrid({
    super.key,
    required this.genres,
    required this.home,
    required this.onGenre,
    this.covers = const {},
    this.onAll,
  });

  final List<GenreDto> genres;
  final HomeDto home;
  final Map<String, String> covers;
  final ValueChanged<GenreDto> onGenre;
  final VoidCallback? onAll;

  @override
  Widget build(BuildContext context) {
    if (genres.isEmpty) return const SizedBox.shrink();
    final theme = ShadTheme.of(context);
    final shown = featuredGenres(genres, covers, home);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.screenGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Jelajahi genre',
                  style: theme.textTheme.sectionTitle,
                ),
              ),
              if (onAll != null)
                ShadButton.ghost(
                  onPressed: onAll,
                  size: ShadButtonSize.sm,
                  child: const Text('Lihat semua'),
                ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: Spacing.md,
            crossAxisSpacing: Spacing.md,
            childAspectRatio: 1.7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final genre in shown)
                GenreCard(
                  label: genreLabel(genre.name),
                  imageUrl: genreCover(genre.name, covers, home),
                  onTap: () => onGenre(genre),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
