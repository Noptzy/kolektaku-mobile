import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/year_filter.dart';
import '../../data/providers/gateway_providers.dart';
import '../../data/providers/library_providers.dart';
import '../../src/rust/dto/media.dart';
import 'search_facets.dart';
import 'search_filters.dart';
import 'search_state.dart';

const searchDebounce = Duration(milliseconds: 300);

class SearchNotifier extends Notifier<SearchState> {
  SearchNotifier(this.kind);

  final MediaKindDto kind;
  Timer? _timer;
  int _request = 0;

  @override
  SearchState build() {
    ref.onDispose(() => _timer?.cancel());
    return const SearchState();
  }

  void onQueryChanged(String text) {
    _timer?.cancel();
    final query = text.trim();
    _request++;
    if (query.isEmpty && !state.hasFacets) {
      state = SearchState(format: state.format, order: state.order);
      return;
    }
    state = state.copyWith(query: query, clearError: true);
    _timer = Timer(searchDebounce, () => _run(query, page: 1));
  }

  Future<void> submit() async {
    _timer?.cancel();
    final query = state.query;
    if (query.isEmpty) return;
    await remember();
    await _run(query, page: 1);
  }

  Future<void> remember() async {
    final query = state.query;
    if (query.isEmpty) return;
    await ref.read(libraryGatewayProvider).addSearch(kind, query);
    ref.invalidate(recentSearchesProvider(kind));
  }

  Future<void> clearRecent() async {
    await ref.read(libraryGatewayProvider).clearSearches(kind);
    ref.invalidate(recentSearchesProvider(kind));
  }

  Future<void> retry() => _run(state.query, page: 1);

  Future<void> loadMore() async {
    if (!state.hasNext || state.status == SearchStatus.loadingMore) return;
    await _run(state.query, page: state.page + 1);
  }

  void setFormat(SearchFormat format) {
    if (format == state.format) return;
    state = state.copyWith(format: format, barrenPages: 0);
    if (state.hasFacets) unawaited(_run(state.query, page: 1));
  }

  Future<void> setYear(YearFilter? year) {
    return setFacets(
      year: year,
      genre: state.genre,
      airing: state.airing,
      origin: state.origin,
    );
  }

  Future<void> setFacets({
    YearFilter? year,
    String? genre,
    SearchAiring airing = SearchAiring.all,
    SearchOrigin origin = SearchOrigin.all,
  }) async {
    if (year == state.year &&
        genre == state.genre &&
        airing == state.airing &&
        origin == state.origin) {
      return;
    }
    _timer?.cancel();
    state = state.copyWith(
      year: year,
      clearYear: year == null,
      genre: genre,
      clearGenre: genre == null,
      airing: airing,
      origin: origin,
      barrenPages: 0,
    );
    await _rerun();
  }

  Future<void> applyFilters({
    required SearchFormat format,
    required SearchOrder order,
    YearFilter? year,
    String? genre,
    SearchAiring airing = SearchAiring.all,
    SearchOrigin origin = SearchOrigin.all,
  }) async {
    final formatChanged = format != state.format;
    state = state.copyWith(format: format, order: order);
    final before = state.hasFacets;
    await setFacets(year: year, genre: genre, airing: airing, origin: origin);
    if (formatChanged && before && state.hasFacets) await _rerun();
  }

  Future<void> _rerun() async {
    if (state.query.isEmpty && !state.hasFacets) {
      _request++;
      state = SearchState(format: state.format, order: state.order);
      return;
    }
    await _run(state.query, page: 1);
  }

  void resetFilters() {
    final hadFacets = state.hasFacets;
    _timer?.cancel();
    state = state.copyWith(
      format: SearchFormat.all,
      order: SearchOrder.relevance,
      clearYear: true,
      clearGenre: true,
      airing: SearchAiring.all,
      origin: SearchOrigin.all,
      barrenPages: 0,
    );
    if (hadFacets) unawaited(_rerun());
  }

  void setOrder(SearchOrder order) {
    state = state.copyWith(order: order);
  }

  Future<void> _run(String query, {required int page}) async {
    if (query.isEmpty && !state.hasFacets) return;
    final request = ++_request;
    final first = page == 1;
    final facets = state;
    state = state.copyWith(
      status: first ? SearchStatus.loading : SearchStatus.loadingMore,
      cards: first ? const [] : null,
      ranQuery: first ? query : null,
      clearError: true,
    );
    try {
      final gateway = ref.read(catalogGatewayProvider);
      final result = facets.hasFacets
          ? await gateway.discover(
              kind: kind,
              query: query.isEmpty ? null : query,
              genre: facets.genre,
              year: facets.year,
              formats: facets.format.formats,
              status: facets.airing.apiName,
              origin: facets.origin.apiName,
              page: page,
            )
          : await gateway.search(kind, query, page);
      if (request != _request) return;
      final before = state.visible.length;
      final next = state.copyWith(
        status: SearchStatus.loaded,
        cards: first ? result.cards : [...state.cards, ...result.cards],
        page: page,
        hasNext: result.hasNextPage,
      );
      final added = next.visible.length - (first ? 0 : before);
      state = next.copyWith(
        barrenPages: first || added > 0 ? 0 : state.barrenPages + 1,
      );
    } on Object catch (error) {
      if (request != _request) return;
      state = state.copyWith(status: SearchStatus.failed, error: error);
    }
  }
}

final searchProvider = NotifierProvider.autoDispose
    .family<SearchNotifier, SearchState, MediaKindDto>(SearchNotifier.new);
