import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../data/providers/source_providers.dart';
import '../../src/rust/dto/media.dart';
import 'source_names.dart';

class SourceNote extends ConsumerWidget {
  const SourceNote({
    super.key,
    required this.kind,
    required this.source,
    required this.loaded,
    required this.expected,
    required this.canSwitch,
  });

  final MediaKindDto kind;
  final String? source;
  final int? loaded;
  final int? expected;
  final bool canSwitch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = source;
    final count = loaded;
    if (id == null || count == null) return const SizedBox.shrink();
    final names = sourceNamesOf(
      ref.watch(sourceStatusProvider).value ?? const [],
      kind,
    );
    final line = sourceLine(names.labels[id], names.summaries[id]);
    final note = completenessNote(
      kind: kind,
      loaded: count,
      expected: expected,
      canSwitch: canSwitch,
    );
    if (line == null && note == null) return const SizedBox.shrink();
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.screenGutter,
        0,
        Spacing.screenGutter,
        Spacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Spacing.xs,
        children: [
          if (line != null)
            Text(
              line,
              key: const Key('source-line'),
              style: theme.textTheme.muted,
            ),
          if (note != null)
            Text(
              note,
              key: const Key('source-completeness'),
              style: theme.textTheme.small.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}
