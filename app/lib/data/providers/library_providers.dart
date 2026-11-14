import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../src/rust/dto/library.dart';
import '../../src/rust/dto/media.dart';
import 'gateway_providers.dart';

final recentSearchesProvider =
    FutureProvider.family<List<String>, MediaKindDto>(
      (ref, kind) => ref.watch(libraryGatewayProvider).searches(kind),
    );

final favoritesProvider =
    FutureProvider.family<List<FavoriteDto>, MediaKindDto>(
      (ref, kind) => ref.watch(libraryGatewayProvider).favorites(kind),
    );

final historyProvider = FutureProvider.family<List<ProgressDto>, MediaKindDto>(
  (ref, kind) => ref.watch(libraryGatewayProvider).history(kind),
);
