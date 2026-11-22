import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routes.dart';
import '../../data/providers/home_providers.dart';
import '../../data/providers/library_providers.dart';
import '../../src/rust/dto/cards.dart';
import '../../src/rust/dto/media.dart';
import '../../src/rust/error.dart';
import '../../widgets/error_state_view.dart';
import '../../widgets/dock_inset.dart';
import '../../widgets/active_filter_chips.dart';
import '../../widgets/infinite_footer.dart';
import '../../widgets/infinite_scroll.dart';
import '../../widgets/media_grid.dart';
import '../../widgets/state_view.dart';
import '../detail/detail_request.dart';
import '../home/home_sections.dart';
import 'search_filter_menu.dart';
import 'search_idle.dart';
import 'search_notifier.dart';
import 'search_state.dart';
import 'search_matches.dart';

class MediaSearchBody extends ConsumerStatefulWidget {
  const MediaSearchBody({
    super.key,
    required this.kind,
    required this.controller,
  });

  final MediaKindDto kind;
  final TextEditingController controller;

  @override
  ConsumerState<MediaSearchBody> createState() => _MediaSearchBodyState();
}

class _MediaSearchBodyState extends ConsumerState<MediaSearchBody> {
  MediaKindDto get _kind => widget.kind;

  SearchNotifier get _notifier => ref.read(searchProvider(_kind).notifier);

  void _pick(String query) {
    widget.controller.text = query;
    _notifier.onQueryChanged(query);
    _notifier.submit();
  }

  void _open(MediaCardDto card) {
    _notifier.remember();
    context.push(
      Routes.detail,
      extra: DetailRequest(kind: _kind, reference: card.reference),
    );
  }

  List<String> _suggestions() {
    final home = ref.watch(homeProvider(_kind)).value;
    if (home == null) return const [];
    return [for (final card in cardsOf(home, 'trending').take(5)) card.title];
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider(_kind));
    return InfiniteScroll(
      enabled:
          !state.isIdle &&
          state.hasNext &&
          state.status == SearchStatus.loaded &&
          !state.autoLoadPaused,
      onMore: _notifier.loadMore,
      builder: (context, scroll) => CustomScrollView(
        controller: scroll,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          if (!state.isIdle)
            SliverToBoxAdapter(
              child: ActiveFilterChips(
                active: activeSearchFilters(state, _notifier),
              ),
            ),
          if (_kind == MediaKindDto.anime && !state.isIdle && !state.hasFacets)
            SliverToBoxAdapter(child: SearchMatches(query: state.ranQuery)),
          ..._body(state),
          const SliverToBoxAdapter(child: DockSpace()),
        ],
      ),
    );
  }

  List<Widget> _body(SearchState state) {
    if (state.isIdle) {
      return [
        SliverToBoxAdapter(
          child: SearchIdle(
            recent: ref.watch(recentSearchesProvider(_kind)).value ?? const [],
            suggestions: _suggestions(),
            onPick: _pick,
            onClear: () => _notifier.clearRecent(),
          ),
        ),
      ];
    }
    final visible = state.visible;
    return switch (state.status) {
      SearchStatus.idle ||
      SearchStatus.loading => [const MediaGridSkeletonSliver()],
      SearchStatus.failed when state.cards.isEmpty => [_failure(state)],
      _ when visible.isEmpty && !state.hasNext => [_empty(state)],
      _ when visible.isEmpty && state.autoLoadPaused => [
        _empty(state),
        SliverToBoxAdapter(child: _footer(state)),
      ],
      _ when visible.isEmpty && state.status != SearchStatus.failed => [
        const MediaGridSkeletonSliver(count: 6),
      ],
      _ when visible.isEmpty => [SliverToBoxAdapter(child: _footer(state))],
      _ => [
        MediaGridSliver(
          cards: visible,
          unitLabel: unitLabelFor(_kind),
          onTap: _open,
        ),
        SliverToBoxAdapter(child: _footer(state)),
      ],
    };
  }

  Widget _failure(SearchState state) {
    final error = state.error;
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 360,
        child: error is BridgeError
            ? ErrorStateView(error: error, onRetry: _notifier.retry)
            : StateView.error(
                title: 'Ada yang tidak beres',
                message: 'Pencarian belum bisa dijalankan.',
                actionLabel: 'Coba lagi',
                onAction: _notifier.retry,
              ),
      ),
    );
  }

  Widget _empty(SearchState state) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 360,
        child: StateView.empty(
          title: 'Tidak ada hasil',
          message: state.query.isEmpty
              ? 'Tidak ada yang cocok dengan filter ini. Coba longgarkan filternya.'
              : 'Tidak menemukan "${state.query}". Coba kata kunci lain.',
        ),
      ),
    );
  }

  Widget _footer(SearchState state) {
    return InfiniteFooter(
      hasMore: state.hasNext,
      loading: state.status == SearchStatus.loadingMore,
      failed: state.status == SearchStatus.failed,
      paused: state.autoLoadPaused,
      onMore: _notifier.loadMore,
    );
  }
}
