import '../../core/year_filter.dart';
import '../../src/rust/service/browse.dart';
import '../../widgets/filter_bar.dart';
import '../../widgets/filter_sheet.dart';
import 'genre_notifier.dart';
import 'genre_state.dart';

const _orderKey = 'order';
const _yearKey = 'year';
const _anyYear = 'all';

const genreInitialChoice = {_orderKey: 'newest', _yearKey: _anyYear};

List<FilterSection> genreSections(int currentYear) {
  return [
    FilterSection(
      key: _orderKey,
      title: 'Urutan',
      options: [
        for (final order in SourceOrderDto.values)
          FilterOption(order.name, orderLabel(order)),
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

FilterChoice genreChoice(GenreState state) => {
  _orderKey: state.order.name,
  _yearKey: state.year?.id ?? _anyYear,
};

Future<void> applyGenreChoice(
  GenreNotifier notifier,
  FilterChoice choice,
) async {
  final year = choice[_yearKey];
  final order = SourceOrderDto.values.firstWhere(
    (value) => value.name == choice[_orderKey],
    orElse: () => SourceOrderDto.newest,
  );
  await notifier.apply(order, year == null ? null : YearFilter.parse(year));
}

List<ActiveFilter> activeGenreFilters(
  GenreState state,
  GenreNotifier notifier,
) {
  return [
    if (state.order != SourceOrderDto.newest)
      ActiveFilter(
        label: orderLabel(state.order),
        onRemove: () => notifier.setOrder(SourceOrderDto.newest),
      ),
    if (state.year != null)
      ActiveFilter(
        label: state.year!.label,
        onRemove: () => notifier.setYear(null),
      ),
  ];
}
