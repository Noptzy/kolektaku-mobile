import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/theme/kolektaku_text.dart';
import '../core/theme/kolektaku_tokens.dart';
import 'hero_slide.dart';
import 'hero_slide_view.dart';

const _actionsHeight = 40.0;

class HeroCarousel extends StatefulWidget {
  const HeroCarousel({
    super.key,
    required this.slides,
    this.onWatch,
    this.onSave,
    this.onTrailer,
    this.watchLabel = 'Tonton',
  });

  final String watchLabel;
  final List<HeroSlide> slides;
  final ValueChanged<int>? onWatch;
  final ValueChanged<int>? onSave;
  final ValueChanged<int>? onTrailer;

  static String counter(int index, int total) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(index + 1)} / ${two(total)}';
  }

  static double heightFor(
    Size screen, {
    double inset = 0,
    TextScaler scaler = TextScaler.noScaling,
  }) {
    final poster = heroPosterWidth(screen.width) / Sizes.posterAspect;
    final synopsis = scaler.scale(heroSynopsisLines * 13 * 1.4);
    final natural =
        inset +
        Spacing.lg +
        poster +
        Spacing.md +
        synopsis.ceilToDouble() +
        Spacing.md +
        _actionsHeight +
        Spacing.lg;
    final cap = screen.height * Sizes.heroMaxHeightFraction;
    return natural < cap ? natural : cap;
  }

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.slides.isEmpty) return const SizedBox.shrink();
    final theme = ShadTheme.of(context);
    final total = widget.slides.length;
    final inset = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: HeroCarousel.heightFor(
        MediaQuery.sizeOf(context),
        inset: inset,
        scaler: MediaQuery.textScalerOf(context),
      ),
      child: Stack(
        children: [
          PageView.builder(
            itemCount: total,
            onPageChanged: (page) => setState(() => _page = page),
            itemBuilder: (context, index) => HeroSlideView(
              slide: widget.slides[index],
              watchLabel: widget.slides[index].actionLabel ?? widget.watchLabel,
              onWatch: widget.onWatch == null
                  ? null
                  : () => widget.onWatch!(index),
              onSave: widget.onSave == null
                  ? null
                  : () => widget.onSave!(index),
              onTrailer: widget.onTrailer == null
                  ? null
                  : () => widget.onTrailer!(index),
            ),
          ),
          Positioned(
            top: inset + Spacing.lg,
            right: Spacing.screenGutter,
            child: Text(
              HeroCarousel.counter(_page, total),
              style: theme.textTheme.badge.copyWith(
                color: theme.colorScheme.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
