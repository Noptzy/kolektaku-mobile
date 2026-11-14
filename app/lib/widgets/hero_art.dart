import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

import 'poster.dart';

class HeroArt extends StatelessWidget {
  const HeroArt({super.key, required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final address = url;
    if (address == null || address.isEmpty) return const PosterPlaceholder();
    return LayoutBuilder(
      builder: (context, constraints) => CachedNetworkImage(
        imageUrl: address,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        memCacheWidth: decodeWidth(
          constraints.maxWidth,
          MediaQuery.devicePixelRatioOf(context),
        ),
        filterQuality: FilterQuality.medium,
        fadeInDuration: imageFadeIn,
        fadeOutDuration: Duration.zero,
        placeholder: (context, url) => const PosterPlaceholder(),
        errorWidget: (context, url, error) => const PosterPlaceholder(),
      ),
    );
  }
}
