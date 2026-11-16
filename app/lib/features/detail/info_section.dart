import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/studio.dart';
import '../../widgets/pressable.dart';
import 'info_rows.dart';

export 'info_rows.dart';

const _rowHeight = Sizes.touchTarget - Spacing.sm;

class InfoSection extends StatelessWidget {
  const InfoSection({
    super.key,
    required this.rows,
    this.actions = const {},
    this.studios = const [],
    this.onStudio,
  });

  final List<(String, String)> rows;
  final Map<String, VoidCallback> actions;
  final List<StudioRefDto> studios;
  final ValueChanged<StudioRefDto>? onStudio;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    if (rows.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Text(
            'Info lengkap tidak tersedia untuk judul ini.',
            style: theme.textTheme.muted,
          ),
        ),
      );
    }
    return SliverList.builder(
      itemCount: rows.length,
      itemBuilder: (context, index) => _row(context, rows[index]),
    );
  }

  Widget _row(BuildContext context, (String, String) row) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.screenGutter,
        vertical: Spacing.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            height: _rowHeight,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(row.$1, style: theme.textTheme.muted),
            ),
          ),
          Expanded(child: _value(context, row)),
        ],
      ),
    );
  }

  Widget _value(BuildContext context, (String, String) row) {
    final theme = ShadTheme.of(context);
    final onStudioTap = onStudio;
    if (row.$1 == studioLabel && studios.isNotEmpty && onStudioTap != null) {
      return Wrap(
        spacing: Spacing.md,
        children: [
          for (final studio in studios)
            _Link(
              key: Key('info-studio-${studio.name}'),
              text: studio.name,
              onTap: () => onStudioTap(studio),
            ),
        ],
      );
    }
    final action = actions[row.$1];
    if (action != null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: _Link(key: Key('info-${row.$1}'), text: row.$2, onTap: action),
      );
    }
    return SizedBox(
      height: _rowHeight,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(row.$2, style: theme.textTheme.p),
      ),
    );
  }
}

class _Link extends StatelessWidget {
  const _Link({super.key, required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Pressable(
      onTap: onTap,
      label: text,
      minSize: _rowHeight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: Spacing.xs,
        children: [
          Flexible(
            child: Text(
              text,
              style: theme.textTheme.p.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(
            LucideIcons.chevronRight,
            size: 16,
            color: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
