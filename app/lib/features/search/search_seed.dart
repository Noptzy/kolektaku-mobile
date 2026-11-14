import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routes.dart';
import '../../src/rust/dto/media.dart';
import 'search_facets.dart';
import 'search_filters.dart';

class SearchSeed {
  const SearchSeed({
    this.kind = MediaKindDto.anime,
    this.query = '',
    this.genre,
    this.format = SearchFormat.all,
    this.airing = SearchAiring.all,
    this.origin = SearchOrigin.all,
  });

  final MediaKindDto kind;
  final String query;
  final String? genre;
  final SearchFormat format;
  final SearchAiring airing;
  final SearchOrigin origin;
}

class SearchSeedNotifier extends Notifier<SearchSeed?> {
  @override
  SearchSeed? build() => null;

  void plant(SearchSeed seed) => state = seed;

  void consume() => state = null;
}

final searchSeedProvider = NotifierProvider<SearchSeedNotifier, SearchSeed?>(
  SearchSeedNotifier.new,
);

void openSearchWith(BuildContext context, WidgetRef ref, SearchSeed seed) {
  ref.read(searchSeedProvider.notifier).plant(seed);
  context.go(Routes.search);
}

SearchFormat formatSeedOf(String? format) {
  for (final candidate in SearchFormat.values) {
    if (candidate != SearchFormat.all && candidate.accepts(format)) {
      return candidate;
    }
  }
  return SearchFormat.all;
}

SearchAiring airingSeedOf(String? status) {
  for (final candidate in SearchAiring.values) {
    if (candidate.apiName != null &&
        candidate.apiName == status?.toUpperCase()) {
      return candidate;
    }
  }
  return SearchAiring.all;
}

SearchOrigin originSeedOf(String? source) {
  for (final candidate in SearchOrigin.values) {
    if (candidate.apiName != null &&
        candidate.apiName == source?.toUpperCase()) {
      return candidate;
    }
  }
  return SearchOrigin.all;
}
