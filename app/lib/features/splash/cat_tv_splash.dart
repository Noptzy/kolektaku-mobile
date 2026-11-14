import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/theme/kolektaku_color_scheme.dart';
import 'tv_scene.dart';

const catAsset = 'assets/brand/kolektaku-cat-transparent.png';
const _stillSeconds = 0.3;
const _clockSeconds = 3200.0;

class CatTvSplash extends StatefulWidget {
  const CatTvSplash({super.key, this.label = 'kolektaku'});

  final String label;

  @override
  State<CatTvSplash> createState() => _CatTvSplashState();
}

class _CatTvSplashState extends State<CatTvSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _clock.stop();
    } else if (!_clock.isAnimating) {
      _clock.repeat();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  double get _seconds =>
      _clock.isAnimating ? _clock.value * _clockSeconds : _stillSeconds;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: kolektakuDarkColorScheme.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 28,
          children: [
            SizedBox(
              width: 348,
              height: 228,
              child: AnimatedBuilder(
                animation: _clock,
                builder: (context, child) => _Scene(seconds: _seconds),
              ),
            ),
            Text(
              widget.label,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                color: kolektakuDarkColorScheme.primary,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Scene extends StatelessWidget {
  const _Scene({required this.seconds});

  final double seconds;

  @override
  Widget build(BuildContext context) {
    final bob = math.sin(seconds * 2 * math.pi / 1.4) * 3;
    final lean = 0.07 + math.sin(seconds * 2 * math.pi / 2.8) * 0.015;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          right: 0,
          top: 0,
          width: 206,
          height: 192,
          child: CustomPaint(
            key: const Key('splash-tv'),
            painter: TvPainter(seconds: seconds),
          ),
        ),
        Positioned(
          left: 4,
          bottom: 0,
          width: 149,
          child: Transform.translate(
            offset: Offset(0, bob),
            child: Transform.rotate(
              angle: lean,
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  glowOf(seconds).withValues(alpha: 0.16),
                  BlendMode.srcATop,
                ),
                child: Image.asset(
                  catAsset,
                  key: const Key('splash-cat'),
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
