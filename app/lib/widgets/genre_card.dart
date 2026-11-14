import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/theme/kolektaku_color_scheme.dart';
import '../core/theme/kolektaku_tokens.dart';
import 'genre_tint.dart';
import 'poster.dart';
import 'pressable.dart';

class GenreCard extends StatelessWidget {
  const GenreCard({
    super.key,
    required this.label,
    this.imageUrl,
    this.onTap,
    this.aspectRatio = 1.7,
  });

  final String label;
  final String? imageUrl;
  final VoidCallback? onTap;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Pressable(
      onTap: onTap,
      label: label,
      child: Poster(
        url: imageUrl,
        placeholder: GenreTint(name: label),
        aspectRatio: aspectRatio,
        radius: Radii.card,
        overlays: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [const Color(0x00000000), theme.colorScheme.scrim],
              ),
            ),
          ),
          Positioned(
            left: Spacing.md,
            right: Spacing.md,
            bottom: Spacing.md,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.large.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
