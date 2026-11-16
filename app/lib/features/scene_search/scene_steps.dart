import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';

const sceneSteps = [
  'Pilih gambar dari anime',
  'Kami cari judul, episode, dan menitnya',
  'Pilih hasilnya, lalu langsung menonton',
];

const _stepBadgeSize = 28.0;

class SceneSteps extends StatelessWidget {
  const SceneSteps({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Spacing.sm,
      children: [
        Text('Cara kerjanya', style: theme.textTheme.large),
        for (var index = 0; index < sceneSteps.length; index++)
          _Step(number: index + 1, text: sceneSteps[index]),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      spacing: Spacing.md,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.primary,
            shape: BoxShape.circle,
          ),
          child: SizedBox.square(
            dimension: _stepBadgeSize,
            child: Center(
              child: Text(
                '$number',
                style: theme.textTheme.small.copyWith(
                  color: scheme.primaryForeground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        Expanded(child: Text(text, style: theme.textTheme.p)),
      ],
    );
  }
}
