import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_color_scheme.dart';
import '../../core/theme/kolektaku_text.dart';
import '../../core/theme/kolektaku_tokens.dart';

const _tiltRadians = 0.12;
const _frameAspect = 16 / 9;

class SceneExamples extends StatelessWidget {
  const SceneExamples({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Spacing.md,
      children: [
        Text('Contoh gambar', style: ShadTheme.of(context).textTheme.large),
        const _ExampleCard(
          key: Key('example-good'),
          good: true,
          caption: 'Gambar seperti ini berhasil',
          hint: 'Frame penuh dan lurus, langsung dari episodenya.',
          picture: _FramePicture(),
        ),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Spacing.md,
          children: [
            Expanded(
              child: _ExampleCard(
                key: Key('example-tilted'),
                good: false,
                caption: 'Sering gagal',
                hint: 'Foto layar yang miring.',
                picture: _TiltedPicture(),
              ),
            ),
            Expanded(
              child: _ExampleCard(
                key: Key('example-fanart'),
                good: false,
                caption: 'Sering gagal',
                hint: 'Gambar buatan penggemar.',
                picture: _SketchPicture(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ExampleCard extends StatelessWidget {
  const _ExampleCard({
    super.key,
    required this.good,
    required this.caption,
    required this.hint,
    required this.picture,
  });

  final bool good;
  final String caption;
  final String hint;
  final Widget picture;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final scheme = theme.colorScheme;
    final verdict = good ? scheme.score : scheme.destructive;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.card,
        borderRadius: Radii.cardShape,
        border: Border.all(color: scheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Spacing.sm,
          children: [
            AspectRatio(aspectRatio: _frameAspect, child: picture),
            Row(
              spacing: Spacing.xs,
              children: [
                Icon(
                  good ? LucideIcons.circleCheck : LucideIcons.circleX,
                  size: 16,
                  color: verdict,
                ),
                Expanded(
                  child: Text(
                    caption,
                    style: theme.textTheme.cardTitle.copyWith(color: verdict),
                  ),
                ),
              ],
            ),
            Text(
              hint,
              style: theme.textTheme.cardMeta.copyWith(
                color: scheme.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Canvas extends StatelessWidget {
  const _Canvas({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.poster),
      child: ColoredBox(color: scheme.secondary, child: child),
    );
  }
}

class _FramePicture extends StatelessWidget {
  const _FramePicture();

  @override
  Widget build(BuildContext context) {
    final muted = ShadTheme.of(context).colorScheme.mutedForeground;
    return _Canvas(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Icon(LucideIcons.mountainSnow, size: 64, color: muted),
          ),
          Positioned(
            top: Spacing.md,
            right: Spacing.xl,
            child: Icon(LucideIcons.sun, size: 24, color: muted),
          ),
        ],
      ),
    );
  }
}

class _TiltedPicture extends StatelessWidget {
  const _TiltedPicture();

  @override
  Widget build(BuildContext context) {
    final muted = ShadTheme.of(context).colorScheme.mutedForeground;
    return _Canvas(
      child: Center(
        child: Transform.rotate(
          angle: _tiltRadians,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Radii.poster),
              border: Border.all(color: muted, width: 3),
            ),
            child: Padding(
              padding: const EdgeInsets.all(Spacing.sm),
              child: Icon(LucideIcons.mountainSnow, size: 28, color: muted),
            ),
          ),
        ),
      ),
    );
  }
}

class _SketchPicture extends StatelessWidget {
  const _SketchPicture();

  @override
  Widget build(BuildContext context) {
    final muted = ShadTheme.of(context).colorScheme.mutedForeground;
    return _Canvas(
      child: Center(
        child: Icon(LucideIcons.pencilLine, size: 36, color: muted),
      ),
    );
  }
}
