import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../data/providers/settings_providers.dart';
import '../../src/rust/dto/settings.dart';
import '../../widgets/option_chip.dart';
import '../settings/settings_edit.dart';
import 'reading_look.dart';

Future<void> showReadingLookSheet(BuildContext context) {
  return showShadSheet<void>(
    context: context,
    side: ShadSheetSide.bottom,
    builder: (sheetContext) => const ReadingLookSheet(),
  );
}

class ReadingLookSheet extends ConsumerWidget {
  const ReadingLookSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(currentSettingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final theme = ShadTheme.of(context);
    return ShadSheet(
      title: const Text('Tampilan baca'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Spacing.md,
        children: [
          Text(
            readingSample,
            key: const Key('look-sample'),
            style: paragraphStyle(
              theme.textTheme.p,
              settings.readingSize,
              settings.readingSpacing,
            ),
          ),
          Text('Ukuran huruf', style: theme.textTheme.small),
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: [
              for (final size in ReadingSizeDto.values)
                OptionChip(
                  key: Key('size-${size.name}'),
                  label: readingSizeNames[size]!,
                  selected: settings.readingSize == size,
                  onTap: () =>
                      notifier.change((now) => now.copyWith(readingSize: size)),
                ),
            ],
          ),
          Text('Jarak baris', style: theme.textTheme.small),
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: [
              for (final spacing in ReadingSpacingDto.values)
                OptionChip(
                  key: Key('spacing-${spacing.name}'),
                  label: readingSpacingNames[spacing]!,
                  selected: settings.readingSpacing == spacing,
                  onTap: () => notifier.change(
                    (now) => now.copyWith(readingSpacing: spacing),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
