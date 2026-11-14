import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/theme/kolektaku_text.dart';
import '../../../core/theme/kolektaku_tokens.dart';
import 'component_samples.dart';
import 'gallery_section.dart';
import 'text_samples.dart';
import 'token_swatches.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ColoredBox(
      color: theme.colorScheme.background,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: Spacing.screenGutter),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.screenGutter,
              ),
              child: Text('Galeri komponen', style: theme.textTheme.heroTitle),
            ),
            const SizedBox(height: Spacing.xl),
            const _Padded(
              child: GallerySection(title: 'Warna', child: TokenSwatches()),
            ),
            const _Padded(
              child: GallerySection(title: 'Huruf', child: TextSamples()),
            ),
            const HeroSample(),
            const SizedBox(height: Spacing.xl),
            const RailSamples(),
            const SizedBox(height: Spacing.xl),
            const GallerySection(
              title: 'Genre',
              titleInset: Spacing.screenGutter,
              child: GenreSamples(),
            ),
            const GallerySection(
              title: 'Memuat',
              titleInset: Spacing.screenGutter,
              child: SkeletonSamples(),
            ),
            const _Padded(child: StateSamples()),
          ],
        ),
      ),
    );
  }
}

class _Padded extends StatelessWidget {
  const _Padded({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.screenGutter),
      child: child,
    );
  }
}
