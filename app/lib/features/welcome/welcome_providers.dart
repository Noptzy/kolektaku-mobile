import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/providers/home_providers.dart';
import '../../src/rust/dto/media.dart';
import '../home/home_sections.dart';
import 'welcome_store.dart';

const defaultWelcomeStore = FileWelcomeStore(getApplicationSupportDirectory);
const wallCoverLimit = 24;

final welcomeStoreProvider = Provider<WelcomeStore>(
  (ref) => defaultWelcomeStore,
);

final welcomeCoversProvider = FutureProvider<List<String>>((ref) async {
  final urls = <String>{};
  for (final kind in MediaKindDto.values) {
    try {
      final home = await ref.watch(homeProvider(kind).future);
      for (final card in cardsOf(home, 'trending')) {
        final url = card.coverUrl;
        if (url != null) urls.add(url);
      }
    } on Object {
      continue;
    }
  }
  return urls.take(wallCoverLimit).toList();
});
