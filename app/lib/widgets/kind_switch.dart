import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/theme/kolektaku_tokens.dart';
import '../src/rust/dto/media.dart';
import 'pressable.dart';

const _outerRadius = 16.0;
const _innerRadius = 12.0;
const _frameWidth = 2.0;

String kindSwitchLabel(MediaKindDto kind) =>
    kind == MediaKindDto.anime ? 'Anime' : 'Komik';

IconData kindSwitchIcon(MediaKindDto kind) =>
    kind == MediaKindDto.anime ? LucideIcons.film : LucideIcons.bookOpen;

class KindSwitch extends StatelessWidget {
  const KindSwitch({super.key, required this.value, required this.onChanged});

  final MediaKindDto value;
  final ValueChanged<MediaKindDto> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.screenGutter),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.card,
          borderRadius: BorderRadius.circular(_outerRadius),
          border: Border.all(color: scheme.primary, width: _frameWidth),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.xs),
          child: Row(
            spacing: Spacing.xs,
            children: [
              for (final kind in MediaKindDto.values)
                Expanded(
                  child: _Segment(
                    key: Key('kind-${kind.name}'),
                    kind: kind,
                    selected: kind == value,
                    onTap: () => onChanged(kind),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    super.key,
    required this.kind,
    required this.selected,
    required this.onTap,
  });

  final MediaKindDto kind;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final scheme = theme.colorScheme;
    final ink = selected ? scheme.primaryForeground : scheme.mutedForeground;
    return Pressable(
      onTap: onTap,
      selected: selected,
      label: kindSwitchLabel(kind),
      minSize: Sizes.touchTarget,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.background,
          borderRadius: BorderRadius.circular(_innerRadius),
        ),
        child: SizedBox(
          height: Sizes.touchTarget - Spacing.sm,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: Spacing.sm,
            children: [
              Icon(kindSwitchIcon(kind), size: 20, color: ink),
              Text(
                kindSwitchLabel(kind),
                style: theme.textTheme.small.copyWith(
                  color: ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
