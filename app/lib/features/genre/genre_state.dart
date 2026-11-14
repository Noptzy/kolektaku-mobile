import '../../core/year_filter.dart';
import '../../src/rust/dto/cards.dart';
import '../../src/rust/dto/discover.dart';
import '../../src/rust/service/browse.dart';

enum GenreStatus { loading, loaded, loadingMore, failed }

String orderLabel(SourceOrderDto order) => switch (order) {
  SourceOrderDto.newest => 'Terbaru',
  SourceOrderDto.oldest => 'Terlama',
  SourceOrderDto.az => 'A-Z',
  SourceOrderDto.za => 'Z-A',
};

DiscoverSortDto discoverSortOf(SourceOrderDto order) => switch (order) {
  SourceOrderDto.newest => DiscoverSortDto.newest,
  SourceOrderDto.oldest => DiscoverSortDto.oldest,
  SourceOrderDto.az => DiscoverSortDto.az,
  SourceOrderDto.za => DiscoverSortDto.za,
};

class GenreState {
  const GenreState({
    this.cards = const [],
    this.page = 0,
    this.hasNext = false,
    this.status = GenreStatus.loading,
    this.error,
    this.order = SourceOrderDto.newest,
    this.year,
  });

  final List<MediaCardDto> cards;
  final int page;
  final bool hasNext;
  final GenreStatus status;
  final Object? error;
  final SourceOrderDto order;
  final YearFilter? year;

  GenreState copyWith({
    List<MediaCardDto>? cards,
    int? page,
    bool? hasNext,
    GenreStatus? status,
    Object? error,
    bool clearError = false,
    SourceOrderDto? order,
    YearFilter? year,
    bool clearYear = false,
  }) {
    return GenreState(
      cards: cards ?? this.cards,
      page: page ?? this.page,
      hasNext: hasNext ?? this.hasNext,
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
      order: order ?? this.order,
      year: clearYear ? null : (year ?? this.year),
    );
  }
}
