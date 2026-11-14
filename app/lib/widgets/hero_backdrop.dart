import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'poster.dart';

const _blurSigma = 26.0;
const _backdropDecodeWidth = 160;

class HeroBackdrop extends StatelessWidget {
  const HeroBackdrop({super.key, required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    final address = url;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: scheme.card),
        if (address != null && address.isNotEmpty)
          ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: _blurSigma,
              sigmaY: _blurSigma,
              tileMode: TileMode.clamp,
            ),
            child: CachedNetworkImage(
              imageUrl: address,
              fit: BoxFit.cover,
              memCacheWidth: _backdropDecodeWidth,
              fadeInDuration: imageFadeIn,
              fadeOutDuration: Duration.zero,
              errorWidget: (context, url, error) => const SizedBox.shrink(),
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0, 0.22, 0.6, 1],
              colors: [
                scheme.background.withValues(alpha: 0.9),
                scheme.background.withValues(alpha: 0.25),
                scheme.background.withValues(alpha: 0.55),
                scheme.background,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
