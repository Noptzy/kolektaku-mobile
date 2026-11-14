import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../src/rust/dto/cards.dart';
import '../../src/rust/dto/library.dart';
import '../../src/rust/dto/media.dart';
import '../../src/rust/dto/sources.dart';
import 'gateway_providers.dart';

final homeProvider = FutureProvider.family<HomeDto, MediaKindDto>(
  (ref, kind) => ref.watch(catalogGatewayProvider).home(kind),
);

final genresProvider = FutureProvider.family<List<GenreDto>, MediaKindDto>(
  (ref, kind) => ref.watch(catalogGatewayProvider).genres(kind),
);

final genreCoversProvider =
    FutureProvider.family<Map<String, String>, MediaKindDto>((ref, kind) async {
      final genres = await ref.watch(genresProvider(kind).future);
      if (genres.isEmpty) return const {};
      try {
        final covers = await ref.watch(catalogGatewayProvider).genreCovers(
          kind,
          [for (final genre in genres) genre.name],
        );
        return {for (final cover in covers) cover.genre: cover.coverUrl};
      } on Object {
        return const {};
      }
    });

final continueProvider = FutureProvider.family<List<ProgressDto>, MediaKindDto>(
  (ref, kind) => ref.watch(libraryGatewayProvider).continueList(kind),
);
