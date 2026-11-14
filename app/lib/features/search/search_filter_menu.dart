import '../../core/genre_names.dart';
import '../../core/year_filter.dart';
import '../../src/rust/dto/media.dart';
import '../../widgets/filter_bar.dart';
import '../../widgets/filter_links.dart';
import '../../widgets/filter_sheet.dart';
import 'search_facets.dart';
import 'search_filters.dart';
import 'search_notifier.dart';
import 'search_state.dart';

const _formatKey = 'format';
const _genreKey = 'genre';
const _airingKey = 'airing';
const _originKey = 'origin';
const _orderKey = 'order';
const _yearKey = 'year';
const _anyYear = 'all';
const _any = 'all';

const searchInitialChoice = {
  _formatKey: 'all',
  _genreKey: _any,
  _airingKey: 'all',
  _originKey: 'all',
  _orderKey: 'relevance',
  _yearKey: _anyYear,
};

List<FilterSection> searchSections(MediaKindDto kind, int currentYear) {
  final anime = kind == MediaKindDto.anime;
  return [
    FilterSection(
      key: _genreKey,
      title: 'Genre',
      options: [
        const FilterOption(_any, 'Semua'),
        for (final genre in searchGenres)
          FilterOption(genre, genreLabel(genre)),
      ],
    ),
    FilterSection(
      key: _formatKey,
      title: 'Format',
      options: [
        for (final format in SearchFormat.forKind(kind))
          FilterOption(format.name, format.label),
      ],
    ),
    FilterSection(
      key: _airingKey,
      title: anime ? 'Status tayang' : 'Status terbit',
      options: [
        for (final airing in SearchAiring.values)
          FilterOption(airing.name, airing.label),
      ],
    ),
    FilterSection(
      key: _originKey,
      title: 'Sumber cerita',
      options: [
        for (final origin in SearchOrigin.values)
          FilterOption(origin.name, origin.label),
      ],
    ),
    FilterSection(
      key: _orderKey,
      title: 'Urutan',
      options: [
        for (final order in SearchOrder.values)
          FilterOption(order.name, order.label),
      ],
    ),
    FilterSection(
      key: _yearKey,
      title: 'Tahun',
      options: [
        const FilterOption(_anyYear, 'Semua'),
        for (final year in yearOptions(currentYear))
          FilterOption(year.id, year.label),
      ],
    ),
  ];
}

FilterLinkSection studioLinks(void Function(String name) onOpen) {
  return FilterLinkSection(
    key: 'studio',
    title: 'Studio populer',
    hint: 'Membuka pencarian studio, lalu pilih untuk melihat karyanya.',
    options: [for (final name in popularStudios) FilterOption(name, name)],
    onOpen: onOpen,
  );
}

FilterChoice searchChoice(SearchState state) => {
  _formatKey: state.format.name,
  _genreKey: state.genre ?? _any,
  _airingKey: state.airing.name,
  _originKey: state.origin.name,
  _orderKey: state.order.name,
  _yearKey: state.year?.id ?? _anyYear,
};

T _pick<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}

Future<void> applySearchChoice(
  SearchNotifier notifier,
  FilterChoice choice,
) async {
  final year = choice[_yearKey];
  final genre = choice[_genreKey];
  await notifier.applyFilters(
    format: _pick(SearchFormat.values, choice[_formatKey], SearchFormat.all),
    order: _pick(SearchOrder.values, choice[_orderKey], SearchOrder.relevance),
    year: year == null ? null : YearFilter.parse(year),
    genre: genre == null || genre == _any ? null : genre,
    airing: _pick(SearchAiring.values, choice[_airingKey], SearchAiring.all),
    origin: _pick(SearchOrigin.values, choice[_originKey], SearchOrigin.all),
  );
}

List<ActiveFilter> activeSearchFilters(
  SearchState state,
  SearchNotifier notifier,
) {
  return [
    if (state.genre != null)
      ActiveFilter(
        label: genreLabel(state.genre!),
        onRemove: () => notifier.setFacets(
          year: state.year,
          airing: state.airing,
          origin: state.origin,
        ),
      ),
    if (state.format != SearchFormat.all)
      ActiveFilter(
        label: state.format.label,
        onRemove: () => notifier.setFormat(SearchFormat.all),
      ),
    if (state.airing != SearchAiring.all)
      ActiveFilter(
        label: state.airing.label,
        onRemove: () => notifier.setFacets(
          year: state.year,
          genre: state.genre,
          origin: state.origin,
        ),
      ),
    if (state.origin != SearchOrigin.all)
      ActiveFilter(
        label: 'Dari ${state.origin.label.toLowerCase()}',
        onRemove: () => notifier.setFacets(
          year: state.year,
          genre: state.genre,
          airing: state.airing,
        ),
      ),
    if (state.order != SearchOrder.relevance)
      ActiveFilter(
        label: state.order.label,
        onRemove: () => notifier.setOrder(SearchOrder.relevance),
      ),
    if (state.year != null)
      ActiveFilter(
        label: state.year!.label,
        onRemove: () => notifier.setYear(null),
      ),
  ];
}
