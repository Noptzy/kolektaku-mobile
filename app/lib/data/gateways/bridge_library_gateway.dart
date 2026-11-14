import '../../src/rust/api/library.dart' as api;
import '../../src/rust/dto/library.dart';
import '../../src/rust/dto/media.dart';
import 'library_gateway.dart';

class BridgeLibraryGateway implements LibraryGateway {
  const BridgeLibraryGateway();

  @override
  Future<List<FavoriteDto>> favorites(MediaKindDto kind) =>
      api.libraryFavorites(kind: kind);

  @override
  Future<bool> isFavorite(MediaKindDto kind, MediaRefDto reference) =>
      api.libraryIsFavorite(kind: kind, reference: reference);

  @override
  Future<bool> toggleFavorite(FavoriteDto favorite) =>
      api.libraryToggleFavorite(favorite: favorite);

  @override
  Future<List<ProgressDto>> history(MediaKindDto kind) =>
      api.libraryHistory(kind: kind);

  @override
  Future<List<ProgressDto>> continueList(MediaKindDto kind) =>
      api.libraryContinue(kind: kind);

  @override
  Future<void> saveProgress(ProgressDto progress) =>
      api.librarySaveProgress(progress: progress);

  @override
  Future<ProgressDto?> progressFor(
    MediaKindDto kind,
    MediaRefDto reference,
    double unitNumber,
  ) => api.libraryProgressFor(
    kind: kind,
    reference: reference,
    unitNumber: unitNumber,
  );

  @override
  Future<ProgressDto?> lastProgress(MediaKindDto kind, MediaRefDto reference) =>
      api.libraryLastProgress(kind: kind, reference: reference);

  @override
  Future<void> removeProgress(
    MediaKindDto kind,
    MediaRefDto reference,
    double unitNumber,
  ) => api.libraryRemoveProgress(
    kind: kind,
    reference: reference,
    unitNumber: unitNumber,
  );

  @override
  Future<void> clearHistory(MediaKindDto kind) =>
      api.libraryClearHistory(kind: kind);

  @override
  Future<UnitOrderDto> unitOrder(MediaKindDto kind, MediaRefDto reference) =>
      api.libraryUnitOrder(kind: kind, reference: reference);

  @override
  Future<void> setUnitOrder(
    MediaKindDto kind,
    MediaRefDto reference,
    UnitOrderDto order,
  ) => api.librarySetUnitOrder(kind: kind, reference: reference, order: order);

  @override
  Future<List<String>> searches(MediaKindDto kind) =>
      api.librarySearches(kind: kind);

  @override
  Future<void> addSearch(MediaKindDto kind, String query) =>
      api.libraryAddSearch(kind: kind, query: query);

  @override
  Future<void> clearSearches(MediaKindDto kind) =>
      api.libraryClearSearches(kind: kind);

  @override
  Future<String?> preference(String name) => api.libraryPreference(name: name);

  @override
  Future<void> setPreference(String name, String value) =>
      api.librarySetPreference(name: name, value: value);
}
