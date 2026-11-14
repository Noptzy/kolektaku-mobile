import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_text.dart';
import '../../core/theme/kolektaku_tokens.dart';
import '../../widgets/pressable.dart';

typedef Swatch<T> = (T, Color, String);

class SwatchRow<T> extends StatelessWidget {
  const SwatchRow({
    super.key,
    required this.title,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final List<Swatch<T>> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final scheme = theme.colorScheme;
    final chosen = options.firstWhere(
      (option) => option.$1 == value,
      orElse: () => options.first,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.screenGutter,
        vertical: Spacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Spacing.sm,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: theme.textTheme.cardTitle)),
              Text(
                chosen.$3,
                style: theme.textTheme.cardMeta.copyWith(
                  color: scheme.mutedForeground,
                ),
              ),
            ],
          ),
          Wrap(
            spacing: Spacing.md,
            runSpacing: Spacing.sm,
            children: [
              for (final option in options)
                _Dot(
                  key: Key('swatch-${option.$1}'),
                  color: option.$2,
                  label: option.$3,
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

class _Dot extends StatelessWidget {
  const _Dot({
    super.key,
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    final ink = color.computeLuminance() > 0.5
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);
    return Pressable(
      onTap: onTap,
      label: label,
      selected: selected,
      minSize: 44,
      child: SizedBox.square(
        dimension: 44,
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? scheme.primary : scheme.border,
                width: selected ? 3 : 1,
              ),
            ),
            child: SizedBox.square(
              dimension: 36,
              child: selected
                  ? Icon(LucideIcons.check, size: 18, color: ink)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
