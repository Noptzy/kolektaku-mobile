import '../../core/year_filter.dart';
import '../../src/rust/api/browse.dart' as browse;
import '../../src/rust/api/detail.dart' as detail_api;
import '../../src/rust/api/people.dart' as people;
import '../../src/rust/dto/cards.dart';
import '../../src/rust/dto/covers.dart';
import '../../src/rust/dto/discover.dart';
import '../../src/rust/dto/media.dart';
import '../../src/rust/dto/profile.dart';
import '../../src/rust/dto/profile_summary.dart';
import '../../src/rust/dto/sources.dart';
import '../../src/rust/service/browse.dart';
import 'catalog_gateway.dart';

class BridgeCatalogGateway implements CatalogGateway {
  const BridgeCatalogGateway();

  @override
  Future<void> clearCache() => browse.clearCatalogCache();

  @override
  Future<HomeDto> home(MediaKindDto kind) => browse.home(kind: kind);

  @override
  Future<CardPageDto> search(MediaKindDto kind, String query, int page) =>
      browse.search(kind: kind, query: query, page: page);

  @override
  Future<List<GenreDto>> genres(MediaKindDto kind) => browse.genres(kind: kind);

  @override
  Future<CardPageDto> discover({
    required MediaKindDto kind,
    required int page,
    String? query,
    String? genre,
    YearFilter? year,
    List<String> formats = const [],
    String? status,
    String? origin,
    DiscoverSortDto sort = DiscoverSortDto.relevance,
  }) => browse.discover(
    kind: kind,
    filter: DiscoverFilterDto(
      query: query,
      genre: genre,
      yearFrom: year?.fromYear,
      yearTo: year?.toYear,
      formats: formats,
      status: status,
      origin: origin,
      sort: sort,
    ),
    page: page,
  );

  @override
  Future<List<GenreCoverDto>> genreCovers(
    MediaKindDto kind,
    List<String> genres,
  ) => browse.genreCovers(kind: kind, genres: genres);

  @override
  Future<CardPageDto> byGenre(
    MediaKindDto kind,
    String slug,
    int page,
    SourceOrderDto order,
  ) => browse.byGenre(kind: kind, slug: slug, page: page, order: order);

  @override
  Future<DetailViewDto> detail(MediaKindDto kind, MediaRefDto reference) =>
      detail_api.mediaDetail(kind: kind, reference: reference);

  @override
  Future<ProfileDto> profile(ProfileKindDto kind, BigInt id) =>
      people.profile(kind: kind, id: id);

  @override
  Future<List<ProfileSummaryDto>> searchPeople(
    ProfileKindDto kind,
    String query,
  ) => people.searchPeople(kind: kind, query: query);

  @override
  Future<UnitsDto> units(MediaRefDto reference, {String? source}) =>
      detail_api.units(reference: reference, source: source);

  @override
  Future<List<SourceLinkDto>> selectSource(
    MediaKindDto kind,
    MediaRefDto reference,
    String source,
    String item,
  ) => detail_api.selectSource(
    kind: kind,
    reference: reference,
    source: source,
    item: item,
  );

  @override
  Future<void> forgetMatch(MediaKindDto kind, MediaRefDto reference) =>
      detail_api.forgetMatch(kind: kind, reference: reference);

  @override
  Future<List<SourceItemDto>> sourceCandidates(String source, String query) =>
      browse.sourceCandidates(source: source, query: query);
}
