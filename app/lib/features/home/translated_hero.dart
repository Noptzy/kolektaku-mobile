import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/translation_providers.dart';
import '../../widgets/hero_carousel.dart';
import '../../widgets/hero_slide.dart';

class TranslatedHeroCarousel extends ConsumerWidget {
  const TranslatedHeroCarousel({
    super.key,
    required this.slides,
    required this.onWatch,
    this.autoPlay,
  });

  final List<HeroSlide> slides;
  final ValueChanged<int> onWatch;
  final Duration? autoPlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final originals = [for (final slide in slides) slide.synopsis ?? ''];
    final shown = shownFor(
      ref.watch(translatedTextsProvider(TextBatch(originals))),
      originals,
    );
    return HeroCarousel(
      autoPlay: autoPlay,
      slides: [
        for (var index = 0; index < slides.length; index++)
          slides[index].withSynopsis(
            shown.translated ? shown.texts[index] : slides[index].synopsis,
          ),
      ],
      onWatch: onWatch,
    );
  }
}
