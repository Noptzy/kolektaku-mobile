import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/theme/kolektaku_tokens.dart';
import 'filter_model.dart';
import 'option_chip.dart';
import 'pressable.dart';

const filterListMaxOptions = 6;

class FilterSectionView extends StatelessWidget {
  const FilterSectionView({
    super.key,
    required this.section,
    required this.selected,
    required this.onPick,
  });

  final FilterSection section;
  final String? selected;
  final ValueChanged<String> onPick;

  bool get _asList => section.options.length <= filterListMaxOptions;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Spacing.sm,
      children: [
        Text(section.title, style: theme.textTheme.large),
        if (_asList)
          _Rows(section: section, selected: selected, onPick: onPick)
        else
          _Chips(section: section, selected: selected, onPick: onPick),
      ],
    );
  }
}

class _Chips extends StatelessWidget {
  const _Chips({
    required this.section,
    required this.selected,
    required this.onPick,
  });

  final FilterSection section;
  final String? selected;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Spacing.sm,
      runSpacing: Spacing.sm,
      children: [
        for (final option in section.options)
          OptionChip(
            key: Key('${section.key}-${option.id}'),
            label: option.label,
            selected: option.id == selected,
            onTap: () => onPick(option.id),
          ),
      ],
    );
  }
}

class _Rows extends StatelessWidget {
  const _Rows({
    required this.section,
    required this.selected,
    required this.onPick,
  });

  final FilterSection section;
  final String? selected;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    final options = section.options;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.accent,
        borderRadius: Radii.cardShape,
      ),
      child: ClipRRect(
        borderRadius: Radii.cardShape,
        child: Column(
          children: [
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0)
                SizedBox(height: 1, child: ColoredBox(color: scheme.border)),
              _Row(
                key: Key('${section.key}-${options[i].id}'),
                option: options[i],
                selected: options[i].id == selected,
                onTap: () => onPick(options[i].id),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    super.key,
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final FilterOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final scheme = theme.colorScheme;
    return Pressable(
      onTap: onTap,
      selected: selected,
      label: option.label,
      minSize: Sizes.touchTarget,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.p.copyWith(
                  color: scheme.foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: selected ? 1 : 0,
              duration: Motion.quick,
              child: Icon(LucideIcons.check, size: 20, color: scheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
