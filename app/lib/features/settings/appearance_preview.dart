import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../widgets/option_chip.dart';

class AppearancePreview extends StatelessWidget {
  const AppearancePreview({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.screenGutter,
        vertical: Spacing.sm,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.card,
          borderRadius: Radii.cardShape,
          border: Border.all(color: scheme.primary, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: Spacing.md,
            children: [
              Wrap(
                spacing: Spacing.md,
                runSpacing: Spacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ShadButton(
                    key: const Key('accent-preview-button'),
                    onPressed: () {},
                    child: const Text('Tombol utama'),
                  ),
                  OptionChip(label: 'Aktif', selected: true, onTap: () {}),
                  const ShadBadge(child: Text('Baru')),
                ],
              ),
              const ShadProgress(
                key: Key('accent-preview-progress'),
                value: 0.6,
                minHeight: 6,
              ),
              Row(
                spacing: Spacing.sm,
                children: [
                  Icon(LucideIcons.house, size: 20, color: scheme.primary),
                  Text(
                    'Selengkapnya',
                    style: theme.textTheme.small.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
