import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/routes.dart';
import 'package:kolektaku/features/search/people_search_providers.dart';
import 'package:kolektaku/features/search/person_row.dart';
import 'package:kolektaku/features/search/search_notifier.dart';
import 'package:kolektaku/features/search/search_tab_screen.dart';
import 'package:kolektaku/src/rust/dto/profile.dart';
import 'package:kolektaku/src/rust/dto/profile_summary.dart';

import '../../support/screen_harness.dart';
import 'search_support.dart';

ProfileSummaryDto person(ProfileKindDto kind, int id, String name) =>
    ProfileSummaryDto(kind: kind, id: BigInt.from(id), name: name);

Future<ScreenHarness> open(
  WidgetTester tester, {
  void Function(ScreenHarness harness)? prepare,
}) async {
  final harness = ScreenHarness();
  harness.catalog.searchResult = page([card(1, title: 'Hasil Anime')]);
  prepare?.call(harness);
  await harness.pump(tester, const SearchTabScreen());
  return harness;
}

Future<void> type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(EditableText), text);
  await tester.pump(searchDebounce + const Duration(milliseconds: 50));
  await tester.pumpAndSettle();
}

void main() {
  group('namesMatching', () {
    final people = [
      person(ProfileKindDto.studio, 1, 'Studio Ghibli'),
      person(ProfileKindDto.studio, 2, 'Kyoto Animation'),
      person(ProfileKindDto.character, 3, 'Nezuko Kamado'),
    ];

    test('keeps only the names that contain every typed word', () {
      expect(namesMatching(people, 'ghibli').map((p) => p.name), [
        'Studio Ghibli',
      ]);
      expect(namesMatching(people, 'KAMADO nezuko').map((p) => p.name), [
        'Nezuko Kamado',
      ]);
      expect(namesMatching(people, 'ghibli kyoto'), isEmpty);
    });

    test('a blank search matches nobody', () {
      expect(namesMatching(people, '   '), isEmpty);
    });
  });

  group('one box finds everything', () {
    testWidgets('a studio name shows the studio above the anime', (
      tester,
    ) async {
      await open(
        tester,
        prepare: (harness) => harness.catalog.peopleResult = [
          person(ProfileKindDto.studio, 21, 'Studio Ghibli'),
        ],
      );
      await type(tester, 'ghibli');
      expect(find.text('Studio Ghibli'), findsOneWidget);
      final studioAt = tester.getTopLeft(find.byType(PersonRow).first).dy;
      final animeAt = tester.getTopLeft(find.text('Hasil Anime')).dy;
      expect(studioAt, lessThan(animeAt));
    });

    testWidgets('characters and staff are separated under their own headings', (
      tester,
    ) async {
      await open(
        tester,
        prepare: (harness) {
          harness.catalog.onPeople = (kind, query) async => switch (kind) {
            ProfileKindDto.character => [
              person(ProfileKindDto.character, 1, 'Nezuko Kamado'),
            ],
            ProfileKindDto.staff => [
              person(ProfileKindDto.staff, 2, 'Nezuko Voice'),
            ],
            ProfileKindDto.studio => const [],
          };
        },
      );
      await type(tester, 'nezuko');
      expect(find.text('Karakter'), findsOneWidget);
      expect(find.text('Staf'), findsOneWidget);
      expect(find.text('Studio'), findsNothing);
      expect(find.text('Nezuko Kamado'), findsOneWidget);
      expect(find.text('Nezuko Voice'), findsOneWidget);
    });

    testWidgets('names that do not contain the words are not shown', (
      tester,
    ) async {
      await open(
        tester,
        prepare: (harness) => harness.catalog.peopleResult = [
          person(ProfileKindDto.studio, 5, 'Bones'),
        ],
      );
      await type(tester, 'naruto');
      expect(find.byType(PersonRow), findsNothing);
      expect(find.text('Hasil Anime'), findsOneWidget);
    });

    testWidgets('manga that matches appears as its own rail', (tester) async {
      final harness = await open(
        tester,
        prepare: (harness) => harness.catalog.mangaSearchResult = page([
          card(7, title: 'Manga Cocok', format: 'MANGA'),
        ]),
      );
      await type(tester, 'berserk');
      expect(find.byKey(const Key('manga-matches')), findsOneWidget);
      expect(find.text('Manga Cocok'), findsOneWidget);
      expect(find.text('Hasil Anime'), findsOneWidget);
      await tester.tap(find.text('Manga Cocok'));
      await tester.pumpAndSettle();
      expect(harness.visits.single.path, Routes.detail);
    });

    testWidgets(
      'every comic match is listed in a grid that only scrolls down',
      (tester) async {
        await open(
          tester,
          prepare: (harness) => harness.catalog.mangaSearchResult = page([
            for (var i = 0; i < 9; i++)
              card(100 + i, title: 'Komik $i', format: 'MANGA'),
          ]),
        );
        await type(tester, 'berserk');
        final grid = find.byKey(const Key('manga-matches'));
        expect(grid, findsOneWidget);
        expect(
          find.descendant(
            of: grid,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Scrollable &&
                  widget.axisDirection == AxisDirection.right,
            ),
          ),
          findsNothing,
        );
        expect(find.text('Komik 0'), findsOneWidget);
        expect(find.text('Komik 8'), findsOneWidget);
        expect(find.byKey(const Key('see-all-Komik')), findsOneWidget);
      },
    );

    testWidgets('a novel that matches appears as its own rail', (tester) async {
      final harness = await open(
        tester,
        prepare: (harness) => harness.catalog.novelSearchResult = page([
          card(8, title: 'Novel Cocok', format: 'NOVEL'),
        ]),
      );
      await type(tester, 'overlord');
      expect(find.byKey(const Key('novel-matches')), findsOneWidget);
      expect(find.byKey(const Key('manga-matches')), findsNothing);
      expect(find.text('Novel Cocok'), findsOneWidget);
      await tester.tap(find.text('Novel Cocok'));
      await tester.pumpAndSettle();
      expect(harness.visits.single.path, Routes.detail);
    });

    testWidgets('no manga match leaves no rail and no extra heading', (
      tester,
    ) async {
      await open(tester);
      await type(tester, 'berserk');
      expect(find.byKey(const Key('manga-matches')), findsNothing);
      expect(find.text('Anime'), findsNothing);
    });

    testWidgets('the Anime heading shows only when something sits above', (
      tester,
    ) async {
      await open(
        tester,
        prepare: (harness) => harness.catalog.peopleResult = [
          person(ProfileKindDto.studio, 21, 'Studio Ghibli'),
        ],
      );
      await type(tester, 'ghibli');
      expect(find.text('Anime'), findsOneWidget);
    });

    testWidgets('a short text does not ask for people or manga', (
      tester,
    ) async {
      final harness = await open(tester);
      await type(tester, 'ab');
      expect(harness.catalog.peopleAsks, isEmpty);
      expect(harness.catalog.mangaSearches, isEmpty);
      expect(harness.catalog.novelSearches, isEmpty);
    });

    testWidgets('failures on the side lookups never hide the anime', (
      tester,
    ) async {
      await open(
        tester,
        prepare: (harness) => harness.catalog.peopleError = StateError('down'),
      );
      await type(tester, 'ghibli');
      expect(find.byType(PersonRow), findsNothing);
      expect(find.text('Hasil Anime'), findsOneWidget);
    });

    testWidgets('active filters hide the side matches and keep browsing', (
      tester,
    ) async {
      final harness = await open(
        tester,
        prepare: (harness) {
          harness.catalog.peopleResult = [
            person(ProfileKindDto.studio, 21, 'Studio Ghibli'),
          ];
          harness.catalog.discoverResult = page([
            card(2, title: 'Hasil Filter'),
          ]);
        },
      );
      await type(tester, 'ghibli');
      expect(find.byType(PersonRow), findsOneWidget);
      await tester.tap(find.byKey(const Key('open-filters')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('genre-Drama')));
      await tester.tap(find.byKey(const Key('genre-Drama')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('filter-apply')));
      await tester.pumpAndSettle();
      expect(find.byType(PersonRow), findsNothing);
      expect(find.text('Hasil Filter'), findsOneWidget);
      expect(harness.catalog.discoverAsks.last['genre'], 'Drama');
    });
  });
}
