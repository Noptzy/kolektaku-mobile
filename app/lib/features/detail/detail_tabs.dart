import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/media.dart';
import '../../widgets/pressable.dart';

enum DetailTab { units, characters, info, related }

String tabLabel(DetailTab tab, MediaKindDto kind) => switch (tab) {
  DetailTab.units => kind == MediaKindDto.anime ? 'Episode' : 'Chapter',
  DetailTab.characters => 'Karakter',
  DetailTab.info => 'Info',
  DetailTab.related => 'Terkait',
};

class DetailTabs extends StatelessWidget {
  const DetailTabs({
    super.key,
    required this.selected,
    required this.kind,
    required this.onChanged,
  });

  final DetailTab selected;
  final MediaKindDto kind;
  final ValueChanged<DetailTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
        child: Row(
          children: [
            for (final tab in DetailTab.values)
              Pressable(
                onTap: () => onChanged(tab),
                selected: tab == selected,
                minSize: Sizes.touchTarget,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: tab == selected
                            ? scheme.primary
                            : const Color(0x00000000),
                        width: 3,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.md,
                      vertical: Spacing.md,
                    ),
                    child: Text(
                      tabLabel(tab, kind),
                      style: theme.textTheme.small.copyWith(
                        fontWeight: FontWeight.w700,
                        color: tab == selected
                            ? scheme.foreground
                            : scheme.mutedForeground,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
