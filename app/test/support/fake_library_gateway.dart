import 'package:kolektaku/data/gateways/library_gateway.dart';
import 'package:kolektaku/src/rust/dto/library.dart';
import 'package:kolektaku/src/rust/dto/media.dart';

class FakeLibraryGateway implements LibraryGateway {
  List<ProgressDto> continueResult = const [];
  List<ProgressDto> historyResult = const [];
  List<FavoriteDto> favoriteResult = const [];
  List<String> searchHistory = [];
  final Map<String, String> prefs = {};
  UnitOrderDto order = UnitOrderDto.asc;
  final List<FavoriteDto> toggled = [];
  final List<ProgressDto> saved = [];
  final List<String> removed = [];
  final List<String> cleared = [];

  @override
  Future<List<FavoriteDto>> favorites(MediaKindDto kind) async =>
      favoriteResult.where((item) => item.kind == kind).toList();

  @override
  Future<bool> isFavorite(MediaKindDto kind, MediaRefDto reference) async =>
      favoriteResult.any((item) => item.reference == reference);

  @override
  Future<bool> toggleFavorite(FavoriteDto favorite) async {
    toggled.add(favorite);
    final exists = favoriteResult.any(
      (item) => item.reference == favorite.reference,
    );
    favoriteResult = exists
        ? favoriteResult
              .where((item) => item.reference != favorite.reference)
              .toList()
        : [...favoriteResult, favorite];
    return !exists;
  }

  @override
  Future<List<ProgressDto>> history(MediaKindDto kind) async =>
      historyResult.where((item) => item.kind == kind).toList();

  @override
  Future<List<ProgressDto>> continueList(MediaKindDto kind) async =>
      continueResult.where((item) => item.kind == kind).toList();

  @override
  Future<void> saveProgress(ProgressDto progress) async {
    saved.add(progress);
  }

  @override
  Future<ProgressDto?> progressFor(
    MediaKindDto kind,
    MediaRefDto reference,
    double unitNumber,
  ) async {
    for (final item in [...saved, ...historyResult]) {
      if (item.reference == reference && item.unitNumber == unitNumber) {
        return item;
      }
    }
    return null;
  }

  @override
  Future<ProgressDto?> lastProgress(
    MediaKindDto kind,
    MediaRefDto reference,
  ) async {
    for (final item in [...saved.reversed, ...historyResult]) {
      if (item.reference == reference) return item;
    }
    return null;
  }

  @override
  Future<void> removeProgress(
    MediaKindDto kind,
    MediaRefDto reference,
    double unitNumber,
  ) async {
    removed.add('${reference.id}|$unitNumber');
    historyResult = historyResult
        .where(
          (item) =>
              !(item.reference == reference && item.unitNumber == unitNumber),
        )
        .toList();
    continueResult = continueResult
        .where(
          (item) =>
              !(item.reference == reference && item.unitNumber == unitNumber),
        )
        .toList();
  }

  @override
  Future<void> clearHistory(MediaKindDto kind) async {
    cleared.add('history|${kind.name}');
    historyResult = historyResult.where((item) => item.kind != kind).toList();
    continueResult = continueResult.where((item) => item.kind != kind).toList();
  }

  @override
  Future<UnitOrderDto> unitOrder(
    MediaKindDto kind,
    MediaRefDto reference,
  ) async => order;

  @override
  Future<void> setUnitOrder(
    MediaKindDto kind,
    MediaRefDto reference,
    UnitOrderDto value,
  ) async {
    order = value;
  }

  @override
  Future<List<String>> searches(MediaKindDto kind) async => searchHistory;

  @override
  Future<void> addSearch(MediaKindDto kind, String query) async {
    searchHistory = [query, ...searchHistory.where((item) => item != query)];
  }

  @override
  Future<void> clearSearches(MediaKindDto kind) async {
    cleared.add('searches|${kind.name}');
    searchHistory = [];
  }

  @override
  Future<String?> preference(String name) async => prefs[name];

  @override
  Future<void> setPreference(String name, String value) async {
    prefs[name] = value;
  }
}
