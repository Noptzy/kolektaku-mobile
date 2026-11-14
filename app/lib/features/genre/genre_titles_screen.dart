import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/genre_names.dart';
import '../../core/routes.dart';
import '../../src/rust/dto/cards.dart';
import '../../src/rust/dto/media.dart';
import '../../src/rust/dto/sources.dart';
import '../../src/rust/error.dart';
import '../../widgets/error_state_view.dart';
import '../../widgets/filter_bar.dart';
import '../../widgets/filter_sheet.dart';
import '../../widgets/infinite_footer.dart';
import '../../widgets/infinite_scroll.dart';
import '../../widgets/media_grid.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/state_view.dart';
import '../detail/detail_request.dart';
import '../home/home_sections.dart';
import 'genre_notifier.dart';
import 'genre_state.dart';
import 'genre_filter_menu.dart';

class GenreTitlesScreen extends ConsumerWidget {
  const GenreTitlesScreen({super.key, required this.kind, required this.genre});

  final MediaKindDto kind;
  final GenreDto genre;

  GenreArgs get _args => (kind: kind, slug: genre.slug, name: genre.name);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(genreProvider(_args));
    final notifier = ref.read(genreProvider(_args).notifier);
    final scheme = ShadTheme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.background,
      child: SafeArea(
        child: InfiniteScroll(
          enabled: state.hasNext && state.status == GenreStatus.loaded,
          onMore: notifier.loadMore,
          builder: (context, scroll) => CustomScrollView(
            controller: scroll,
            slivers: [
              SliverToBoxAdapter(
                child: ScreenHeader(title: genreLabel(genre.name)),
              ),
              SliverToBoxAdapter(
                child: FilterBar(
                  onOpen: () => _openFilters(context, state, notifier),
                  active: activeGenreFilters(state, notifier),
                ),
              ),
              ..._body(context, state, notifier),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openFilters(
    BuildContext context,
    GenreState state,
    GenreNotifier notifier,
  ) async {
    final choice = await showFilterSheet(
      context,
      sections: genreSections(DateTime.now().year),
      current: genreChoice(state),
      initial: genreInitialChoice,
    );
    if (choice != null) await applyGenreChoice(notifier, choice);
  }

  List<Widget> _body(
    BuildContext context,
    GenreState state,
    GenreNotifier notifier,
  ) {
    if (state.status == GenreStatus.loading) {
      return const [MediaGridSkeletonSliver()];
    }
    if (state.status == GenreStatus.failed && state.cards.isEmpty) {
      return [_failure(state.error, notifier)];
    }
    if (state.cards.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: SizedBox(
            height: 360,
            child: StateView.empty(
              title: 'Belum ada judul',
              message: 'Genre ini belum punya judul yang bisa ditampilkan.',
            ),
          ),
        ),
      ];
    }
    return [
      MediaGridSliver(
        cards: state.cards,
        unitLabel: unitLabelFor(kind),
        onTap: (MediaCardDto card) => context.push(
          Routes.detail,
          extra: DetailRequest(kind: kind, reference: card.reference),
        ),
      ),
      SliverToBoxAdapter(child: _footer(state, notifier)),
    ];
  }

  Widget _failure(Object? error, GenreNotifier notifier) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 360,
        child: error is BridgeError
            ? ErrorStateView(error: error, onRetry: notifier.retry)
            : StateView.error(
                title: 'Ada yang tidak beres',
                message: 'Daftar genre belum bisa dimuat.',
                actionLabel: 'Coba lagi',
                onAction: notifier.retry,
              ),
      ),
    );
  }

  Widget _footer(GenreState state, GenreNotifier notifier) {
    return InfiniteFooter(
      hasMore: state.hasNext,
      loading: state.status == GenreStatus.loadingMore,
      failed: state.status == GenreStatus.failed,
      onMore: notifier.loadMore,
    );
  }
}

typedef GenreRouteArgs = ({MediaKindDto kind, GenreDto genre});
