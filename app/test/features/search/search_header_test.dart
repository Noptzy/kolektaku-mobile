import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/search/person_row.dart';
import 'package:kolektaku/features/search/search_notifier.dart';
import 'package:kolektaku/features/search/search_tab_screen.dart';
import 'package:kolektaku/src/rust/dto/profile.dart';
import 'package:kolektaku/src/rust/dto/profile_summary.dart';
import 'package:kolektaku/widgets/option_chip.dart';

import '../../support/screen_harness.dart';
import 'search_support.dart';

ProfileSummaryDto studio(int id, String name) => ProfileSummaryDto(
  kind: ProfileKindDto.studio,
  id: BigInt.from(id),
  name: name,
);

Future<ScreenHarness> open(
  WidgetTester tester, {
  void Function(ScreenHarness harness)? prepare,
}) async {
  final harness = ScreenHarness();
  prepare?.call(harness);
  await harness.pump(tester, const SearchTabScreen());
  return harness;
}

Future<void> type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(EditableText), text);
  await tester.pump(searchDebounce + const Duration(milliseconds: 50));
  await tester.pumpAndSettle();
}

Future<void> openSheet(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('open-filters')));
  await tester.pumpAndSettle();
}

Future<void> pick(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

void main() {
  group('header', () {
    testWidgets('search, camera and filter share one line', (tester) async {
      await open(tester);
      final field = tester.getCenter(find.byType(EditableText)).dy;
      final camera = tester.getCenter(find.byKey(const Key('open-camera'))).dy;
      final filter = tester.getCenter(find.byKey(const Key('open-filters'))).dy;
      expect((camera - field).abs(), lessThan(24));
      expect((filter - field).abs(), lessThan(24));
      expect(find.widgetWithText(OptionChip, 'Anime'), findsNothing);
    });

    testWidgets('the cross appears with text and clears it', (tester) async {
      await open(tester);
      expect(find.byKey(const Key('clear-search')), findsNothing);
      await type(tester, 'naruto');
      expect(find.byKey(const Key('clear-search')), findsOneWidget);
      await tester.tap(find.byKey(const Key('clear-search')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('clear-search')), findsNothing);
      expect(find.text('naruto'), findsNothing);
    });

    testWidgets('there are no scope buttons to choose from', (tester) async {
      await open(tester);
      for (final label in ['Anime', 'Komik', 'Karakter', 'Staf', 'Studio']) {
        expect(find.widgetWithText(OptionChip, label), findsNothing);
      }
      expect(find.text('Cari anime, komik, karakter, studio'), findsOneWidget);
    });

    testWidgets('the badge counts the active filters', (tester) async {
      await open(tester);
      await openSheet(tester);
      await pick(tester, 'genre-Action');
      await pick(tester, 'airing-finished');
      await tester.tap(find.byKey(const Key('filter-apply')));
      await tester.pumpAndSettle();
      expect(find.text('2'), findsOneWidget);
    });
  });

  group('filter sheet', () {
    testWidgets('offers genre, format, status, source and studios', (
      tester,
    ) async {
      await open(tester);
      await openSheet(tester);
      for (final title in [
        'Genre',
        'Format',
        'Status tayang',
        'Sumber cerita',
        'Urutan',
        'Tahun',
        'Studio populer',
      ]) {
        await tester.ensureVisible(find.text(title));
        expect(find.text(title), findsOneWidget, reason: title);
      }
      expect(find.byKey(const Key('genre-Action')), findsOneWidget);
      expect(find.byKey(const Key('origin-manga')), findsOneWidget);
    });

    testWidgets('a chosen genre and status become removable chips', (
      tester,
    ) async {
      final harness = await open(
        tester,
        prepare: (harness) =>
            harness.catalog.discoverResult = page([card(1, title: 'Hasil')]),
      );
      await openSheet(tester);
      await pick(tester, 'genre-Action');
      await pick(tester, 'airing-releasing');
      await tester.tap(find.byKey(const Key('filter-apply')));
      await tester.pumpAndSettle();
      expect(find.text('Hasil'), findsOneWidget);
      expect(find.byKey(const Key('active-Aksi')), findsOneWidget);
      expect(find.byKey(const Key('active-Sedang tayang')), findsOneWidget);
      final ask = harness.catalog.discoverAsks.last;
      expect(ask['genre'], 'Action');
      expect(ask['status'], 'RELEASING');
      expect(ask['query'], isNull);
      await tester.tap(find.byKey(const Key('active-Aksi')));
      await tester.pumpAndSettle();
      expect(harness.catalog.discoverAsks.last['genre'], isNull);
    });

    testWidgets('a studio chip searches for that name and shows the studio', (
      tester,
    ) async {
      final harness = await open(
        tester,
        prepare: (harness) =>
            harness.catalog.peopleResult = [studio(21, 'ufotable Studio')],
      );
      await openSheet(tester);
      await pick(tester, 'studio-ufotable');
      expect(find.byKey(const Key('filter-apply')), findsNothing);
      expect(harness.catalog.searches.last, contains('ufotable'));
      expect(harness.catalog.peopleAsks, contains('studio|ufotable'));
      expect(find.text('ufotable Studio'), findsOneWidget);
    });
  });

  group('studio detection', () {
    testWidgets('a studio name shows the studio above the anime', (
      tester,
    ) async {
      await open(
        tester,
        prepare: (harness) {
          harness.catalog.searchResult = page([card(1, title: 'Spirited')]);
          harness.catalog.peopleResult = [
            studio(21, 'Studio Ghibli'),
            studio(22, 'Ghibli Museum Crew'),
            studio(23, 'Unrelated'),
          ];
        },
      );
      await type(tester, 'ghibli');
      expect(find.text('Studio'), findsWidgets);
      expect(find.byType(PersonRow), findsNWidgets(2));
      expect(find.text('Studio Ghibli'), findsOneWidget);
      expect(find.text('Unrelated'), findsNothing);
      expect(find.text('Spirited'), findsOneWidget);
      final studioAt = tester.getTopLeft(find.byType(PersonRow).first).dy;
      final animeAt = tester.getTopLeft(find.text('Spirited')).dy;
      expect(studioAt, lessThan(animeAt));
    });

    testWidgets('a title that is no studio shows no studio section', (
      tester,
    ) async {
      await open(
        tester,
        prepare: (harness) {
          harness.catalog.searchResult = page([card(1, title: 'Naruto')]);
          harness.catalog.peopleResult = [studio(21, 'Studio Ghibli')];
        },
      );
      await type(tester, 'naruto');
      expect(find.byType(PersonRow), findsNothing);
      expect(find.text('Naruto'), findsOneWidget);
    });

    testWidgets('short text does not look for studios', (tester) async {
      final harness = await open(
        tester,
        prepare: (harness) =>
            harness.catalog.searchResult = page([card(1, title: 'Ab')]),
      );
      await type(tester, 'ab');
      expect(harness.catalog.peopleAsks, isEmpty);
    });

    testWidgets('a failing studio lookup is simply left out', (tester) async {
      await open(
        tester,
        prepare: (harness) {
          harness.catalog.searchResult = page([card(1, title: 'Ghibli Film')]);
          harness.catalog.peopleError = StateError('down');
        },
      );
      await type(tester, 'ghibli');
      expect(find.byType(PersonRow), findsNothing);
      expect(find.text('Ghibli Film'), findsOneWidget);
    });
  });
}
