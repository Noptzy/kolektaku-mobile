import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/sources.dart';
import '../detail/episode_info_map.dart';

class ChapterEnd extends StatelessWidget {
  const ChapterEnd({
    super.key,
    required this.current,
    required this.next,
    required this.onNext,
  });

  final double current;
  final UnitDto? next;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final target = next;
    return Padding(
      padding: const EdgeInsets.all(Spacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: Spacing.md,
        children: [
          Text(
            'Chapter ${numberBadge(current)} selesai',
            style: theme.textTheme.large,
          ),
          if (target != null)
            ShadButton(
              key: const Key('end-next'),
              onPressed: onNext,
              trailing: const Icon(LucideIcons.arrowRight, size: 16),
              child: Text('Chapter ${numberBadge(target.number)}'),
            )
          else
            Text('Ini chapter terakhir.', style: theme.textTheme.muted),
        ],
      ),
    );
  }
}
