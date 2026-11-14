import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/search/search_facets.dart';
import 'package:kolektaku/features/search/search_filters.dart';
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:kolektaku/features/search/search_seed.dart';
import 'package:kolektaku/features/search/search_tab_screen.dart';
import 'package:kolektaku/src/rust/dto/profile.dart';
import 'package:kolektaku/src/rust/dto/profile_summary.dart';

import '../../support/screen_harness.dart';
import 'search_support.dart';

ProviderContainer containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(SearchTabScreen)));

Future<ScreenHarness> open(WidgetTester tester, {SearchSeed? before}) async {
  final harness = ScreenHarness();
  harness.catalog.discoverResult = page([card(1, title: 'Hasil Seed')]);
  harness.catalog.peopleResult = [
    ProfileSummaryDto(
      kind: ProfileKindDto.studio,
      id: BigInt.from(21),
      name: 'Studio Ghibli',
    ),
  ];
  await harness.pump(
    tester,
    const SearchTabScreen(),
    extra: [
      if (before != null)
        searchSeedProvider.overrideWith(() => _Seeded(before)),
    ],
  );
  return harness;
}

class _Seeded extends SearchSeedNotifier {
  _Seeded(this.initial);

  final SearchSeed initial;

  @override
  SearchSeed? build() => initial;
}

Future<void> plant(WidgetTester tester, SearchSeed seed) async {
  containerOf(tester).read(searchSeedProvider.notifier).plant(seed);
  await tester.pumpAndSettle(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('a genre seed browses that genre without typing', (tester) async {
    final harness = await open(tester);
    await plant(tester, const SearchSeed(genre: 'Drama'));
    final ask = harness.catalog.discoverAsks.last;
    expect(ask['genre'], 'Drama');
    expect(ask['query'], isNull);
    expect(find.text('Hasil Seed'), findsOneWidget);
    expect(find.byKey(const Key('active-Drama')), findsOneWidget);
  });

  testWidgets('format, status and origin seeds are all applied', (
    tester,
  ) async {
    final harness = await open(tester);
    await plant(
      tester,
      const SearchSeed(
        format: SearchFormat.movie,
        airing: SearchAiring.finished,
        origin: SearchOrigin.manga,
      ),
    );
    final ask = harness.catalog.discoverAsks.last;
    expect(ask['formats'], ['MOVIE']);
    expect(ask['status'], 'FINISHED');
    expect(ask['origin'], 'MANGA');
  });

  testWidgets('a seed is used up once the tab has taken it', (tester) async {
    await open(tester);
    await plant(tester, const SearchSeed(genre: 'Drama'));
    expect(containerOf(tester).read(searchSeedProvider), isNull);
  });

  testWidgets('a name seed fills the box and finds the studio too', (
    tester,
  ) async {
    final harness = await open(tester);
    await plant(tester, const SearchSeed(query: 'Studio Ghibli'));
    expect(find.text('Studio Ghibli'), findsWidgets);
    expect(harness.catalog.peopleAsks, contains('studio|Studio Ghibli'));
    expect(find.byKey(const Key('open-filters')), findsOneWidget);
  });

  testWidgets('a manga seed browses manga with its own filters', (
    tester,
  ) async {
    final harness = await open(tester);
    await plant(
      tester,
      const SearchSeed(kind: MediaKindDto.manga, genre: 'Drama'),
    );
    expect(harness.catalog.discoverAsks.last['kind'], MediaKindDto.manga);
    expect(harness.catalog.discoverAsks.last['genre'], 'Drama');
  });

  testWidgets('a seed waiting before the tab opens is still applied', (
    tester,
  ) async {
    final harness = await open(
      tester,
      before: const SearchSeed(genre: 'Mystery'),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    expect(harness.catalog.discoverAsks.last['genre'], 'Mystery');
  });

  testWidgets('a seed replaces filters left over from before', (tester) async {
    final harness = await open(tester);
    await plant(tester, const SearchSeed(genre: 'Drama'));
    await plant(tester, const SearchSeed(origin: SearchOrigin.manga));
    final ask = harness.catalog.discoverAsks.last;
    expect(ask['genre'], isNull);
    expect(ask['origin'], 'MANGA');
  });
}
