import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/theme/kolektaku_tokens.dart';

const imageFadeIn = Duration(milliseconds: 160);

int? decodeWidth(double logicalWidth, double pixelRatio) {
  if (!logicalWidth.isFinite || logicalWidth <= 0) return null;
  return (logicalWidth * pixelRatio).round().clamp(1, 2048);
}

class Poster extends StatelessWidget {
  const Poster({
    super.key,
    required this.url,
    this.aspectRatio = Sizes.posterAspect,
    this.radius = Radii.poster,
    this.overlays = const [],
    this.placeholder = const PosterPlaceholder(),
  });

  final String? url;
  final double aspectRatio;
  final double radius;
  final List<Widget> overlays;
  final Widget placeholder;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            LayoutBuilder(
              builder: (context, constraints) =>
                  _image(context, constraints.maxWidth),
            ),
            ...overlays,
          ],
        ),
      ),
    );
  }

  Widget _image(BuildContext context, double width) {
    final address = url;
    if (address == null || address.isEmpty) return placeholder;
    return CachedNetworkImage(
      imageUrl: address,
      fit: BoxFit.cover,
      memCacheWidth: decodeWidth(width, MediaQuery.devicePixelRatioOf(context)),
      filterQuality: FilterQuality.medium,
      fadeInDuration: imageFadeIn,
      fadeOutDuration: Duration.zero,
      placeholder: (context, url) => placeholder,
      errorWidget: (context, url, error) => placeholder,
    );
  }
}

class PosterPlaceholder extends StatelessWidget {
  const PosterPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.card,
      child: Center(
        child: Icon(
          LucideIcons.clapperboard,
          size: 28,
          color: scheme.mutedForeground,
        ),
      ),
    );
  }
}
