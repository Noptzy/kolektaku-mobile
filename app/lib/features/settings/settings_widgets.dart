import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_text.dart';
import '../../core/theme/kolektaku_tokens.dart';
import '../../widgets/option_chip.dart';
import '../../widgets/pressable.dart';

class SettingsHeading extends StatelessWidget {
  const SettingsHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.screenGutter,
        Spacing.xl,
        Spacing.screenGutter,
        Spacing.sm,
      ),
      child: Text(text, style: ShadTheme.of(context).textTheme.sectionTitle),
    );
  }
}

class SettingsNote extends StatelessWidget {
  const SettingsNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.screenGutter,
        vertical: Spacing.xs,
      ),
      child: Text(text, style: ShadTheme.of(context).textTheme.muted),
    );
  }
}

class ChoiceRow<T> extends StatelessWidget {
  const ChoiceRow({
    super.key,
    required this.title,
    required this.options,
    required this.value,
    required this.onChanged,
    this.hint,
  });

  final String title;
  final String? hint;
  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.screenGutter,
        vertical: Spacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Spacing.sm,
        children: [
          Text(title, style: theme.textTheme.cardTitle),
          if (hint != null)
            Text(
              hint!,
              style: theme.textTheme.cardMeta.copyWith(
                color: theme.colorScheme.mutedForeground,
              ),
            ),
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: [
              for (final option in options)
                OptionChip(
                  label: option.$2,
                  selected: option.$1 == value,
                  onTap: () => onChanged(option.$1),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class SwitchRow extends StatelessWidget {
  const SwitchRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.hint,
  });

  final String title;
  final String? hint;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Pressable(
      onTap: () => onChanged(!value),
      label: title,
      minSize: Sizes.touchTarget,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.screenGutter,
          vertical: Spacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(title, style: theme.textTheme.cardTitle),
                  if (hint != null)
                    Text(
                      hint!,
                      style: theme.textTheme.cardMeta.copyWith(
                        color: theme.colorScheme.mutedForeground,
                      ),
                    ),
                ],
              ),
            ),
            ShadSwitch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
