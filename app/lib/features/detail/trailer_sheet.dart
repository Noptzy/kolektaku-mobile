import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../platform/url_opener.dart';
import '../../src/rust/dto/credits.dart';
import '../../widgets/swipe_sheet.dart';
import 'trailer_player.dart';

Future<void> showTrailerSheet(BuildContext context, TrailerDto trailer) {
  return showSwipeSheet<void>(
    context: context,
    builder: (sheetContext) => ShadSheet(
      title: const Text('Trailer'),
      child: TrailerSheetBody(trailer: trailer),
    ),
  );
}

class TrailerSheetBody extends ConsumerWidget {
  const TrailerSheetBody({super.key, required this.trailer});

  final TrailerDto trailer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(trailerPlayerProvider);
    final theme = ShadTheme.of(context);
    final address = trailerUrl(trailer.site, trailer.videoId);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Spacing.md,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: Radii.cardShape,
                border: Border.all(color: theme.colorScheme.border),
              ),
              child: ClipRRect(
                borderRadius: Radii.cardShape,
                child: player(context, trailer),
              ),
            ),
          ),
          if (address != null)
            ShadButton.outline(
              key: const Key('trailer-external'),
              onPressed: () => ref.read(urlOpenerProvider).open(address),
              leading: const Icon(LucideIcons.externalLink, size: 16),
              child: const Flexible(
                child: Text(
                  'Buka di aplikasi lain',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
