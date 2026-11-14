import '../../core/year_filter.dart';
import '../../src/rust/dto/cards.dart';
import 'search_facets.dart';
import 'search_filters.dart';

enum SearchStatus { idle, loading, loaded, loadingMore, failed }

const maxBarrenPages = 3;

class SearchState {
  const SearchState({
    this.query = '',
    this.cards = const [],
    this.page = 0,
    this.hasNext = false,
    this.status = SearchStatus.idle,
    this.error,
    this.format = SearchFormat.all,
    this.order = SearchOrder.relevance,
    this.year,
    this.genre,
    this.airing = SearchAiring.all,
    this.origin = SearchOrigin.all,
    this.ranQuery = '',
    this.barrenPages = 0,
  });

  final String query;
  final List<MediaCardDto> cards;
  final int page;
  final bool hasNext;
  final SearchStatus status;
  final Object? error;
  final SearchFormat format;
  final SearchOrder order;
  final YearFilter? year;
  final String? genre;
  final SearchAiring airing;
  final SearchOrigin origin;
  final String ranQuery;
  final int barrenPages;

  List<MediaCardDto> get visible => filterCards(cards, format, order);

  bool get hasFacets =>
      year != null ||
      genre != null ||
      airing != SearchAiring.all ||
      origin != SearchOrigin.all;

  bool get isIdle => query.isEmpty && !hasFacets;

  bool get autoLoadPaused => barrenPages >= maxBarrenPages;

  SearchState copyWith({
    String? query,
    List<MediaCardDto>? cards,
    int? page,
    bool? hasNext,
    SearchStatus? status,
    Object? error,
    bool clearError = false,
    SearchFormat? format,
    SearchOrder? order,
    YearFilter? year,
    bool clearYear = false,
    String? genre,
    bool clearGenre = false,
    SearchAiring? airing,
    SearchOrigin? origin,
    String? ranQuery,
    int? barrenPages,
  }) {
    return SearchState(
      query: query ?? this.query,
      cards: cards ?? this.cards,
      page: page ?? this.page,
      hasNext: hasNext ?? this.hasNext,
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
      format: format ?? this.format,
      order: order ?? this.order,
      year: clearYear ? null : (year ?? this.year),
      genre: clearGenre ? null : (genre ?? this.genre),
      airing: airing ?? this.airing,
      origin: origin ?? this.origin,
      ranQuery: ranQuery ?? this.ranQuery,
      barrenPages: barrenPages ?? this.barrenPages,
    );
  }
}
