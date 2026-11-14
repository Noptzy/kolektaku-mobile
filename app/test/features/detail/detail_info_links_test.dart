import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/routes.dart';
import 'package:kolektaku/features/detail/detail_request.dart';
import 'package:kolektaku/features/detail/detail_screen.dart';
import 'package:kolektaku/features/profile/profile_request.dart';
import 'package:kolektaku/features/search/search_facets.dart';
import 'package:kolektaku/features/search/search_filters.dart';
import 'package:kolektaku/features/search/search_seed.dart';
import 'package:kolektaku/src/rust/dto/credits.dart';
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:kolektaku/src/rust/dto/profile.dart';
import 'package:kolektaku/src/rust/dto/studio.dart';

import '../../support/screen_harness.dart';
import 'detail_support.dart';

Future<ScreenHarness> open(
  WidgetTester tester, {
  MediaDetailDto? head,
  MediaKindDto kind = MediaKindDto.anime,
}) async {
  final harness = ScreenHarness();
  harness.catalog.detailResult = catalogView(head: head);
  harness.catalog.unitsResult = units(12);
  await harness.pump(
    tester,
    DetailScreen(
      request: DetailRequest(kind: kind, reference: ref(filmId)),
    ),
    size: const Size(390, 1400),
  );
  await tester.tap(find.text('Info'));
  await tester.pumpAndSettle();
  return harness;
}

SearchSeed? seedOf(WidgetTester tester) {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(Text).first),
  );
  return container.read(searchSeedProvider);
}

void main() {
  testWidgets('a studio with an id opens its profile', (tester) async {
    final harness = await open(tester);
    await tester.tap(find.byKey(const Key('info-studio-CoMix Wave Films')));
    await tester.pumpAndSettle();
    final visit = harness.visits.single;
    expect(visit.path, Routes.profile);
    final request = visit.extra! as ProfileRequest;
    expect(request.kind, ProfileKindDto.studio);
    expect(request.id, BigInt.from(1042));
    expect(request.name, 'CoMix Wave Films');
  });

  testWidgets('a studio without an id searches for the name instead', (
    tester,
  ) async {
    final harness = await open(
      tester,
      head: detail(studios: [const StudioRefDto(name: 'Tanpa Nomor')]),
    );
    await tester.tap(find.byKey(const Key('info-studio-Tanpa Nomor')));
    await tester.pumpAndSettle();
    expect(harness.visits.single.path, Routes.search);
    final seed = seedOf(tester)!;
    expect(seed.kind, MediaKindDto.anime);
    expect(seed.query, 'Tanpa Nomor');
  });

  testWidgets('the format row opens a search for that format', (tester) async {
    final harness = await open(tester);
    await tester.tap(find.byKey(const Key('info-Format')));
    await tester.pumpAndSettle();
    expect(harness.visits.single.path, Routes.search);
    final seed = seedOf(tester)!;
    expect(seed.kind, MediaKindDto.anime);
    expect(seed.format, SearchFormat.movie);
  });

  testWidgets('the status row searches by airing state', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('info-Status')));
    await tester.pumpAndSettle();
    expect(seedOf(tester)!.airing, SearchAiring.finished);
  });

  testWidgets('the source material row searches by origin', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('info-Sumber cerita')));
    await tester.pumpAndSettle();
    expect(seedOf(tester)!.origin, SearchOrigin.original);
  });

  testWidgets('rows that lead nowhere stay plain text', (tester) async {
    await open(tester);
    expect(find.byKey(const Key('info-Musim')), findsNothing);
    expect(find.byKey(const Key('info-Durasi')), findsNothing);
    expect(find.text('107 menit'), findsOneWidget);
  });

  testWidgets('a genre chip searches that genre', (tester) async {
    final harness = ScreenHarness();
    harness.catalog.detailResult = catalogView();
    harness.catalog.unitsResult = units(12);
    await harness.pump(
      tester,
      DetailScreen(
        request: DetailRequest(
          kind: MediaKindDto.anime,
          reference: ref(filmId),
        ),
      ),
      size: const Size(390, 1400),
    );
    await tester.tap(find.byKey(const Key('genre-Drama')));
    await tester.pumpAndSettle();
    expect(harness.visits.single.path, Routes.search);
    final seed = seedOf(tester)!;
    expect(seed.genre, 'Drama');
    expect(seed.kind, MediaKindDto.anime);
  });

  test('catalog names map back to the matching filter choice', () {
    expect(formatSeedOf('TV_SHORT'), SearchFormat.tv);
    expect(formatSeedOf('UNKNOWN'), SearchFormat.all);
    expect(formatSeedOf(null), SearchFormat.all);
    expect(airingSeedOf('releasing'), SearchAiring.releasing);
    expect(airingSeedOf('CANCELLED'), SearchAiring.all);
    expect(originSeedOf('LIGHT_NOVEL'), SearchOrigin.lightNovel);
    expect(originSeedOf('OTHER'), SearchOrigin.all);
  });
}
