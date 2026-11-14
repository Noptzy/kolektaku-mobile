import 'package:flutter/widgets.dart';

import '../../../core/theme/kolektaku_tokens.dart';
import '../../../widgets/genre_card.dart';
import '../../../widgets/hero_carousel.dart';
import '../../../widgets/hero_slide.dart';
import '../../../widgets/media_card_skeleton.dart';
import '../../../widgets/media_rail.dart';
import '../../../widgets/state_view.dart';
import '../../../widgets/top10_rail.dart';
import 'gallery_section.dart';
import 'sample_media.dart';

class HeroSample extends StatelessWidget {
  const HeroSample({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = sampleCards(8);
    return HeroCarousel(
      slides: [
        for (var i = 0; i < cards.length; i++)
          HeroSlide.fromCard(cards[i], hasTrailer: i.isEven),
      ],
      onWatch: (_) {},
      onSave: (_) {},
      onTrailer: (_) {},
    );
  }
}

class RailSamples extends StatelessWidget {
  const RailSamples({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = sampleCards(10);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Spacing.xl,
      children: [
        MediaRail(
          title: 'Lanjut nonton',
          cards: cards,
          progressOf: (card) => 0.15 * (cards.indexOf(card) % 6),
        ),
        Top10Rail(title: 'Top 10 hari ini', cards: cards),
        MediaRail(title: 'Episode baru', cards: cards, newOnly: true),
      ],
    );
  }
}

class GenreSamples extends StatelessWidget {
  const GenreSamples({super.key});

  @override
  Widget build(BuildContext context) {
    const names = ['Aksi', 'Komedi', 'Drama', 'Fantasi'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.screenGutter),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: Spacing.md,
        crossAxisSpacing: Spacing.md,
        childAspectRatio: 1.7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [for (final name in names) GenreCard(label: name)],
      ),
    );
  }
}

class SkeletonSamples extends StatelessWidget {
  const SkeletonSamples({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.screenGutter),
      child: Row(
        spacing: Spacing.md,
        children: [
          for (var i = 0; i < 3; i++)
            const Expanded(child: MediaCardSkeleton(animate: false)),
        ],
      ),
    );
  }
}

class StateSamples extends StatelessWidget {
  const StateSamples({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GallerySection(
          title: 'Kosong',
          child: StateView.empty(
            title: 'Belum ada hasil',
            message: 'Coba kata kunci lain.',
          ),
        ),
        GallerySection(
          title: 'Galat',
          child: StateView.error(
            title: 'Gagal memuat',
            message: 'Terjadi masalah saat mengambil data.',
            actionLabel: 'Coba lagi',
            onAction: () {},
          ),
        ),
        GallerySection(
          title: 'Luring',
          child: StateView.offline(onAction: () {}),
        ),
      ],
    );
  }
}
