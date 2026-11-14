import '../../core/year_filter.dart';
import '../../src/rust/dto/cards.dart';
import '../../src/rust/dto/covers.dart';
import '../../src/rust/dto/discover.dart';
import '../../src/rust/dto/media.dart';
import '../../src/rust/dto/profile.dart';
import '../../src/rust/dto/profile_summary.dart';
import '../../src/rust/dto/sources.dart';
import '../../src/rust/service/browse.dart';

abstract interface class CatalogGateway {
  Future<HomeDto> home(MediaKindDto kind);

  Future<CardPageDto> search(MediaKindDto kind, String query, int page);

  Future<List<GenreDto>> genres(MediaKindDto kind);

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
  });

  Future<List<GenreCoverDto>> genreCovers(
    MediaKindDto kind,
    List<String> genres,
  );

  Future<CardPageDto> byGenre(
    MediaKindDto kind,
    String slug,
    int page,
    SourceOrderDto order,
  );

  Future<DetailViewDto> detail(MediaKindDto kind, MediaRefDto reference);

  Future<ProfileDto> profile(ProfileKindDto kind, BigInt id);

  Future<List<ProfileSummaryDto>> searchPeople(
    ProfileKindDto kind,
    String query,
  );

  Future<UnitsDto> units(MediaRefDto reference, {String? source});

  Future<List<SourceLinkDto>> selectSource(
    MediaKindDto kind,
    MediaRefDto reference,
    String source,
    String item,
  );

  Future<void> forgetMatch(MediaKindDto kind, MediaRefDto reference);

  Future<List<SourceItemDto>> sourceCandidates(String source, String query);
}
