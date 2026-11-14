import '../../src/rust/dto/library.dart';
import '../../src/rust/dto/media.dart';

abstract interface class LibraryGateway {
  Future<List<FavoriteDto>> favorites(MediaKindDto kind);

  Future<bool> isFavorite(MediaKindDto kind, MediaRefDto reference);

  Future<bool> toggleFavorite(FavoriteDto favorite);

  Future<List<ProgressDto>> history(MediaKindDto kind);

  Future<List<ProgressDto>> continueList(MediaKindDto kind);

  Future<void> saveProgress(ProgressDto progress);

  Future<ProgressDto?> progressFor(
    MediaKindDto kind,
    MediaRefDto reference,
    double unitNumber,
  );

  Future<ProgressDto?> lastProgress(MediaKindDto kind, MediaRefDto reference);

  Future<void> removeProgress(
    MediaKindDto kind,
    MediaRefDto reference,
    double unitNumber,
  );

  Future<void> clearHistory(MediaKindDto kind);

  Future<UnitOrderDto> unitOrder(MediaKindDto kind, MediaRefDto reference);

  Future<void> setUnitOrder(
    MediaKindDto kind,
    MediaRefDto reference,
    UnitOrderDto order,
  );

  Future<List<String>> searches(MediaKindDto kind);

  Future<void> addSearch(MediaKindDto kind, String query);

  Future<void> clearSearches(MediaKindDto kind);

  Future<String?> preference(String name);

  Future<void> setPreference(String name, String value);
}
