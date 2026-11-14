import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/genre_names.dart';
import '../../core/routes.dart';
import '../../core/theme/kolektaku_tokens.dart';
import '../../data/providers/home_providers.dart';
import '../../src/rust/dto/cards.dart';
import '../../src/rust/dto/media.dart';
import '../../src/rust/dto/sources.dart';
import '../../src/rust/error.dart';
import '../../widgets/error_state_view.dart';
import '../../widgets/genre_card.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/state_view.dart';
import '../home/genre_cover.dart';

class GenreListScreen extends ConsumerWidget {
  const GenreListScreen({super.key, required this.kind});

  final MediaKindDto kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genres = ref.watch(genresProvider(kind));
    final home = ref.watch(homeProvider(kind)).value;
    final covers = ref.watch(genreCoversProvider(kind)).value ?? const {};
    final scheme = ShadTheme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.background,
      child: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Genre'),
            Expanded(
              child: genres.when(
                loading: () => const Center(child: Text('Memuat...')),
                error: (error, stack) => _failure(error, ref),
                data: (items) => _grid(context, items, home, covers),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _failure(Object error, WidgetRef ref) {
    void retry() => ref.invalidate(genresProvider(kind));
    if (error is BridgeError) {
      return ErrorStateView(error: error, onRetry: retry);
    }
    return StateView.error(
      title: 'Ada yang tidak beres',
      message: 'Daftar genre belum bisa dimuat.',
      actionLabel: 'Coba lagi',
      onAction: retry,
    );
  }

  Widget _grid(
    BuildContext context,
    List<GenreDto> items,
    HomeDto? home,
    Map<String, String> covers,
  ) {
    if (items.isEmpty) {
      return const StateView.empty(title: 'Belum ada genre');
    }
    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(Spacing.screenGutter),
      mainAxisSpacing: Spacing.md,
      crossAxisSpacing: Spacing.md,
      childAspectRatio: 1.7,
      children: [
        for (final genre in items)
          GenreCard(
            label: genreLabel(genre.name),
            imageUrl: genreCover(genre.name, covers, home),
            onTap: () =>
                context.push(Routes.genre, extra: (kind: kind, genre: genre)),
          ),
      ],
    );
  }
}
