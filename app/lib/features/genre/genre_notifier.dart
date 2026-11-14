import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/year_filter.dart';
import '../../data/providers/gateway_providers.dart';
import '../../src/rust/dto/media.dart';
import '../../src/rust/service/browse.dart';
import 'genre_state.dart';

typedef GenreArgs = ({MediaKindDto kind, String slug, String name});

class GenreNotifier extends Notifier<GenreState> {
  GenreNotifier(this.args);

  final GenreArgs args;
  int _request = 0;

  @override
  GenreState build() {
    Future.microtask(() => _load(1));
    return const GenreState();
  }

  Future<void> retry() => _load(1);

  Future<void> loadMore() async {
    if (!state.hasNext || state.status == GenreStatus.loadingMore) return;
    await _load(state.page + 1);
  }

  Future<void> setOrder(SourceOrderDto order) => apply(order, state.year);

  Future<void> setYear(YearFilter? year) => apply(state.order, year);

  Future<void> apply(SourceOrderDto order, YearFilter? year) async {
    if (order == state.order && year == state.year) return;
    state = year == null
        ? state.copyWith(order: order, clearYear: true)
        : state.copyWith(order: order, year: year);
    await _load(1);
  }

  Future<void> _load(int page) async {
    final request = ++_request;
    final first = page == 1;
    state = state.copyWith(
      status: first ? GenreStatus.loading : GenreStatus.loadingMore,
      cards: first ? const [] : null,
      clearError: true,
    );
    try {
      final gateway = ref.read(catalogGatewayProvider);
      final year = state.year;
      final result = year == null
          ? await gateway.byGenre(args.kind, args.slug, page, state.order)
          : await gateway.discover(
              kind: args.kind,
              genre: args.name,
              year: year,
              sort: discoverSortOf(state.order),
              page: page,
            );
      if (request != _request) return;
      state = state.copyWith(
        status: GenreStatus.loaded,
        cards: first ? result.cards : [...state.cards, ...result.cards],
        page: page,
        hasNext: result.hasNextPage,
      );
    } on Object catch (error) {
      if (request != _request) return;
      state = state.copyWith(status: GenreStatus.failed, error: error);
    }
  }
}

final genreProvider = NotifierProvider.autoDispose
    .family<GenreNotifier, GenreState, GenreArgs>(GenreNotifier.new);
