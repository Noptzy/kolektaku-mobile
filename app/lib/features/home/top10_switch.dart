import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/media.dart';
import '../../widgets/kind_switch.dart';
import '../../widgets/pressable.dart';

const _segmentWidth = 64.0;
const _segmentHeight = 30.0;

class Top10Switch extends StatelessWidget {
  const Top10Switch({
    super.key,
    required this.kinds,
    required this.selected,
    required this.onChanged,
  });

  final List<MediaKindDto> kinds;
  final MediaKindDto selected;
  final ValueChanged<MediaKindDto> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.card,
        borderRadius: BorderRadius.circular(Radii.poster - 1),
        border: Border.all(color: scheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final kind in kinds)
            _Segment(
              key: Key('top10-switch-${kind.name}'),
              label: kindSwitchLabel(kind),
              selected: kind == selected,
              onTap: () => onChanged(kind),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final scheme = theme.colorScheme;
    return Pressable(
      onTap: onTap,
      selected: selected,
      label: label,
      minSize: Sizes.touchTarget,
      child: SizedBox(
        width: _segmentWidth,
        child: Center(
          child: AnimatedContainer(
            duration: Motion.quick,
            width: _segmentWidth - 6,
            height: _segmentHeight - 6,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? scheme.accent : const Color(0x00000000),
              borderRadius: BorderRadius.circular(Radii.poster - 4),
            ),
            child: Text(
              label,
              maxLines: 1,
              style: theme.textTheme.small.copyWith(
                color: selected ? scheme.foreground : scheme.mutedForeground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
