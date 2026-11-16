import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_text.dart';
import '../../core/theme/kolektaku_tokens.dart';
import '../../widgets/pressable.dart';
import '../../widgets/swipe_sheet.dart';
import '../../widgets/translated_text.dart';

class WatchHeading extends StatelessWidget {
  const WatchHeading({
    super.key,
    required this.title,
    required this.episodeLine,
    this.synopsis,
    this.playing,
  });

  final String title;
  final String episodeLine;
  final String? synopsis;
  final String? playing;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final text = synopsis?.trim() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Spacing.xs,
      children: [
        Text(
          title,
          key: const Key('watch-title'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.h4.copyWith(fontWeight: FontWeight.w800),
        ),
        Text(
          episodeLine,
          key: const Key('watch-episode-line'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.cardTitle.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        if (playing != null)
          Padding(
            padding: const EdgeInsets.only(top: Spacing.xs),
            child: Row(
              spacing: Spacing.xs,
              children: [
                Icon(
                  LucideIcons.radio,
                  size: 14,
                  color: theme.colorScheme.mutedForeground,
                ),
                Flexible(
                  child: Text(
                    playing!,
                    key: const Key('playing-label'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.cardMeta.copyWith(
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (text.isNotEmpty) _Synopsis(text: text, title: title),
      ],
    );
  }
}

class _Synopsis extends StatelessWidget {
  const _Synopsis({required this.text, required this.title});

  final String text;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Pressable(
      key: const Key('watch-synopsis'),
      onTap: () => showSynopsisSheet(context, title: title, text: text),
      label: 'Sinopsis, buka selengkapnya',
      child: Padding(
        padding: const EdgeInsets.only(top: Spacing.xs),
        child: TranslatedText(
          text: text,
          showNote: false,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.cardMeta.copyWith(
            color: theme.colorScheme.mutedForeground,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

Future<void> showSynopsisSheet(
  BuildContext context, {
  required String title,
  required String text,
}) {
  return showSwipeSheet<void>(
    context: context,
    builder: (sheetContext) => ShadSheet(
      title: Text(title),
      description: const Text('Sinopsis'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.md),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.5,
          ),
          child: SingleChildScrollView(
            child: TranslatedText(
              text: text,
              textKey: const Key('synopsis-full'),
              style: ShadTheme.of(sheetContext).textTheme.p
                  .copyWith(height: 1.5),
            ),
          ),
        ),
      ),
    ),
  );
}
