import 'dart:async';

import 'package:flutter/widgets.dart';

import '../core/theme/kolektaku_tokens.dart';
import 'hero_counter.dart';
import 'hero_slide.dart';
import 'hero_slide_view.dart';

const _turnDuration = Duration(milliseconds: 450);
const _loops = 500;

class HeroCarousel extends StatefulWidget {
  const HeroCarousel({
    super.key,
    required this.slides,
    this.onWatch,
    this.onSave,
    this.onTrailer,
    this.watchLabel = 'Tonton',
    this.autoPlay,
  });

  final String watchLabel;
  final List<HeroSlide> slides;
  final ValueChanged<int>? onWatch;
  final ValueChanged<int>? onSave;
  final ValueChanged<int>? onTrailer;
  final Duration? autoPlay;

  static bool showsCounter(int total) => total > 1;

  static String counter(int index, int total) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(index + 1)} / ${two(total)}';
  }

  static double cardHeightFor(Size screen, {double inset = 0}) {
    final margins = inset + Spacing.md * 2;
    final natural =
        (screen.width - Spacing.screenGutter * 2) / Sizes.heroCardAspect;
    final cap = screen.height * Sizes.heroMaxHeightFraction - margins;
    final room = natural < cap ? natural : cap;
    return room < 0 ? 0 : room;
  }

  static double heightFor(Size screen, {double inset = 0}) =>
      inset + Spacing.md * 2 + cardHeightFor(screen, inset: inset);

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  late final PageController _pages = PageController(
    initialPage: widget.slides.length * _loops,
  );
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _page = _pages.initialPage;
    _arm();
  }

  @override
  void didUpdateWidget(HeroCarousel old) {
    super.didUpdateWidget(old);
    if (old.autoPlay != widget.autoPlay ||
        old.slides.length != widget.slides.length) {
      _arm();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pages.dispose();
    super.dispose();
  }

  void _arm() {
    _timer?.cancel();
    _timer = null;
    final every = widget.autoPlay;
    if (every == null || widget.slides.length < 2) return;
    _timer = Timer.periodic(every, (_) => _turn());
  }

  void _turn() {
    if (!mounted || !TickerMode.of(context) || !_pages.hasClients) return;
    if (MediaQuery.disableAnimationsOf(context)) return;
    _pages.nextPage(duration: _turnDuration, curve: Curves.easeOutCubic);
  }

  int get _index => _page % widget.slides.length;

  @override
  Widget build(BuildContext context) {
    if (widget.slides.isEmpty) return const SizedBox.shrink();
    final total = widget.slides.length;
    final inset = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: HeroCarousel.heightFor(MediaQuery.sizeOf(context), inset: inset),
      child: Listener(
        onPointerDown: (_) => _timer?.cancel(),
        onPointerUp: (_) => _arm(),
        onPointerCancel: (_) => _arm(),
        child: Stack(
          children: [
            PageView.builder(
              controller: _pages,
              onPageChanged: (page) => setState(() => _page = page),
              itemBuilder: (context, position) {
                final index = position % total;
                final slide = widget.slides[index];
                return HeroSlideView(
                  slide: slide,
                  watchLabel: slide.actionLabel ?? widget.watchLabel,
                  onWatch: widget.onWatch == null
                      ? null
                      : () => widget.onWatch!(index),
                  onSave: widget.onSave == null
                      ? null
                      : () => widget.onSave!(index),
                  onTrailer: widget.onTrailer == null
                      ? null
                      : () => widget.onTrailer!(index),
                );
              },
            ),
            if (HeroCarousel.showsCounter(total))
              Positioned(
                top: inset + Spacing.md + Spacing.md,
                right: Spacing.screenGutter + Spacing.md,
                child: HeroCounter(text: HeroCarousel.counter(_index, total)),
              ),
          ],
        ),
      ),
    );
  }
}
