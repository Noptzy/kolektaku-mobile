import 'package:kolektaku/core/year_filter.dart';
import 'package:kolektaku/data/gateways/catalog_gateway.dart';
import 'package:kolektaku/src/rust/dto/cards.dart';
import 'package:kolektaku/src/rust/dto/covers.dart';
import 'package:kolektaku/src/rust/dto/discover.dart';
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:kolektaku/src/rust/dto/profile.dart';
import 'package:kolektaku/src/rust/dto/profile_summary.dart';
import 'package:kolektaku/src/rust/dto/sources.dart';
import 'package:kolektaku/src/rust/service/browse.dart';

import 'fake_cache_clearing.dart';

class FakeCatalogGateway with FakeCacheClearing implements CatalogGateway {
  HomeDto homeResult = const HomeDto(sections: [], notices: []);
  List<GenreDto> genreResult = const [];
  List<GenreCoverDto> coverResult = const [];
  Object? coverError;
  final List<List<String>> coverAsks = [];
  CardPageDto searchResult = const CardPageDto(
    cards: [],
    hasNextPage: false,
    notices: [],
  );
  CardPageDto discoverResult = const CardPageDto(
    cards: [],
    hasNextPage: false,
    notices: [],
  );
  Future<CardPageDto> Function(Map<String, Object?> ask)? onDiscover;
  final List<Map<String, Object?>> discoverAsks = [];
  Object? homeError;
  Future<HomeDto> Function(MediaKindDto kind)? onHome;
  Object? searchError;
  Future<CardPageDto> Function(
    MediaKindDto kind,
    String slug,
    int page,
    SourceOrderDto order,
  )?
  onGenre;
  Future<CardPageDto> Function(MediaKindDto kind, String query, int page)?
  onSearch;
  DetailViewDto? detailResult;
  ProfileDto? profileResult;
  Object? profileError;
  Future<ProfileDto> Function(ProfileKindDto kind, BigInt id)? onProfile;
  final List<String> profileAsks = [];
  List<ProfileSummaryDto> peopleResult = const [];
  Object? peopleError;
  Future<List<ProfileSummaryDto>> Function(ProfileKindDto kind, String query)?
  onPeople;
  final List<String> peopleAsks = [];
  UnitsDto? unitsResult;
  Object? unitsError;
  List<SourceLinkDto> selectResult = const [];
  List<SourceItemDto> candidateResult = const [];
  int homeCalls = 0;
  int detailCalls = 0;
  final List<String?> unitSources = [];
  Object? detailError;
  int genreCalls = 0;
  final List<String> searches = [];
  final List<String> mangaSearches = [];
  CardPageDto mangaSearchResult = const CardPageDto(
    cards: [],
    hasNextPage: false,
    notices: [],
  );
  final List<String> novelSearches = [];
  CardPageDto novelSearchResult = const CardPageDto(
    cards: [],
    hasNextPage: false,
    notices: [],
  );
  final List<String> genrePages = [];
  final List<String> selected = [];
  final List<String> forgotten = [];

  @override
  Future<HomeDto> home(MediaKindDto kind) async {
    homeCalls++;
    final handler = onHome;
    if (handler != null) return handler(kind);
    final error = homeError;
    if (error != null) throw error;
    return homeResult;
  }

  @override
  Future<CardPageDto> search(MediaKindDto kind, String query, int page) async {
    if (kind == MediaKindDto.manga) {
      mangaSearches.add('$query|$page');
      return mangaSearchResult;
    }
    if (kind == MediaKindDto.novel) {
      novelSearches.add('$query|$page');
      return novelSearchResult;
    }
    searches.add('${kind.name}|$query|$page');
    final handler = onSearch;
    if (handler != null) return handler(kind, query, page);
    final error = searchError;
    if (error != null) throw error;
    return searchResult;
  }

  @override
  Future<List<GenreDto>> genres(MediaKindDto kind) async {
    genreCalls++;
    return genreResult;
  }

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
  }) async {
    final ask = <String, Object?>{
      'kind': kind,
      'page': page,
      'query': query,
      'genre': genre,
      'year': year,
      'formats': formats,
      'status': status,
      'origin': origin,
      'sort': sort,
    };
    discoverAsks.add(ask);
    final handler = onDiscover;
    if (handler != null) return handler(ask);
    return discoverResult;
  }

  @override
  Future<List<GenreCoverDto>> genreCovers(
    MediaKindDto kind,
    List<String> genres,
  ) async {
    coverAsks.add(genres);
    final error = coverError;
    if (error != null) throw error;
    return coverResult;
  }

  @override
  Future<CardPageDto> byGenre(
    MediaKindDto kind,
    String slug,
    int page,
    SourceOrderDto order,
  ) async {
    genrePages.add('${kind.name}|$slug|$page|${order.name}');
    final handler = onGenre;
    if (handler != null) return handler(kind, slug, page, order);
    return searchResult;
  }

  @override
  Future<DetailViewDto> detail(MediaKindDto kind, MediaRefDto reference) async {
    detailCalls++;
    final error = detailError;
    if (error != null) throw error;
    return detailResult!;
  }

  @override
  Future<List<ProfileSummaryDto>> searchPeople(
    ProfileKindDto kind,
    String query,
  ) async {
    peopleAsks.add('${kind.name}|$query');
    final handler = onPeople;
    if (handler != null) return handler(kind, query);
    final error = peopleError;
    if (error != null) throw error;
    return [
      for (final person in peopleResult)
        if (person.kind == kind) person,
    ];
  }

  @override
  Future<ProfileDto> profile(ProfileKindDto kind, BigInt id) async {
    profileAsks.add('${kind.name}|$id');
    final handler = onProfile;
    if (handler != null) return handler(kind, id);
    final error = profileError;
    if (error != null) throw error;
    return profileResult!;
  }

  @override
  Future<UnitsDto> units(MediaRefDto reference, {String? source}) async {
    unitSources.add(source);
    final error = unitsError;
    if (error != null) throw error;
    return unitsResult!;
  }

  @override
  Future<List<SourceLinkDto>> selectSource(
    MediaKindDto kind,
    MediaRefDto reference,
    String source,
    String item,
  ) async {
    selected.add('$source|$item');
    return selectResult;
  }

  @override
  Future<void> forgetMatch(MediaKindDto kind, MediaRefDto reference) async {
    forgotten.add(reference.id.toString());
  }

  @override
  Future<List<SourceItemDto>> sourceCandidates(
    String source,
    String query,
  ) async => candidateResult;
}
