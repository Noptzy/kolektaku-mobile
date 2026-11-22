import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/routes.dart';
import 'package:kolektaku/features/detail/detail_request.dart';
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:kolektaku/src/rust/dto/cards.dart';

import 'home_support.dart';

Future<void> scrollDown(WidgetTester tester, [double by = 2500]) async {
  await tester.drag(find.byType(CustomScrollView), Offset(0, -by));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'there is no search bar, no camera and no title on the home page',
    (tester) async {
      await openHome(tester);
      expect(find.text('Cari anime'), findsNothing);
      expect(find.text('Cari manga'), findsNothing);
      expect(find.bySemanticsLabel('Cari dari gambar'), findsNothing);
      expect(find.text('Kolektaku'), findsNothing);
    },
  );

  testWidgets('the hero mixes anime and manga', (tester) async {
    await openHome(tester);
    expect(find.text('01 / 07'), findsOneWidget);
    expect(find.text('Tonton'), findsOneWidget);
    expect(find.byKey(const Key('hero-label')), findsOneWidget);
    expect(find.text('Rating tertinggi minggu ini'), findsOneWidget);
  });

  testWidgets('both kinds get their own rails', (tester) async {
    await openHome(tester);
    for (final title in [
      'Top 10 hari ini',
      'Episode baru',
      'Chapter baru',
      'Anime musim ini',
      'Anime populer',
      'Komik populer',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
  });

  testWidgets('a rail of popular novels closes the home', (tester) async {
    await openHome(
      tester,
      prepare: (harness) =>
          harness.catalog.onHome = (kind) async =>
              homeOf(kind == MediaKindDto.novel ? 'N' : 'A'),
    );
    expect(find.text('Novel populer'), findsOneWidget);
    final novel = tester.getTopLeft(find.text('Novel populer')).dy;
    final comics = tester.getTopLeft(find.text('Komik populer')).dy;
    expect(novel, greaterThan(comics));
  });

  testWidgets('without novels there is no novel rail', (tester) async {
    await openHome(
      tester,
      prepare: (harness) => harness.catalog.onHome = (kind) async =>
          kind == MediaKindDto.novel
          ? const HomeDto(sections: [], notices: [])
          : homeOf('A'),
    );
    expect(find.text('Novel populer'), findsNothing);
    expect(find.text('Anime populer'), findsOneWidget);
  });

  testWidgets('a failing novel feed leaves the rest of the home alone', (
    tester,
  ) async {
    await openHome(
      tester,
      prepare: (harness) => harness.catalog.onHome = (kind) async {
        if (kind == MediaKindDto.novel) throw StateError('down');
        return homeOf('A');
      },
    );
    expect(find.text('Novel populer'), findsNothing);
    expect(find.text('Top 10 hari ini'), findsOneWidget);
    expect(find.text('Coba lagi'), findsNothing);
  });

  testWidgets('liking anime ranks anime first and puts its rails higher', (
    tester,
  ) async {
    await openHome(tester);
    expect(find.text('A top 1'), findsOneWidget);
    expect(find.text('M top 1'), findsNothing);
    final latestAnime = tester.getTopLeft(find.text('Episode baru')).dy;
    final latestManga = tester.getTopLeft(find.text('Chapter baru')).dy;
    expect(latestAnime, lessThan(latestManga));
  });

  testWidgets('the switch ranks the other kind on the same rail', (
    tester,
  ) async {
    await openHome(tester);
    await tester.tap(find.byKey(const Key('top10-switch-manga')));
    await tester.pumpAndSettle();
    expect(find.text('M top 1'), findsOneWidget);
    expect(find.text('A top 1'), findsNothing);
    expect(find.text('Top 10 hari ini'), findsOneWidget);
  });

  testWidgets('liking manga ranks manga first and puts its rails higher', (
    tester,
  ) async {
    await openHome(tester, prefersAnime: false);
    expect(find.text('M top 1'), findsOneWidget);
    expect(find.text('A top 1'), findsNothing);
    final latestAnime = tester.getTopLeft(find.text('Episode baru')).dy;
    final latestManga = tester.getTopLeft(find.text('Chapter baru')).dy;
    expect(latestManga, lessThan(latestAnime));
    expect(find.text('Baca'), findsOneWidget);
    expect(find.text('Tonton'), findsNothing);
  });

  testWidgets('a title already on the home is not repeated in this season', (
    tester,
  ) async {
    await openHome(
      tester,
      prepare: (harness) => harness.catalog.onHome = (kind) async {
        final home = homeOf(kind == MediaKindDto.manga ? 'M' : 'A');
        if (kind != MediaKindDto.anime) return home;
        final latest = home.sections.firstWhere((s) => s.id == 'latest');
        final seasonal = home.sections.firstWhere((s) => s.id == 'seasonal');
        final shared = latest.cards.first;
        return HomeDto(
          sections: [
            for (final section in home.sections)
              if (section.id == 'seasonal')
                HomeSectionDto(
                  id: 'seasonal',
                  cards: [shared, ...seasonal.cards],
                )
              else
                section,
          ],
          notices: const [],
        );
      },
    );
    await scrollDown(tester, 1800);
    expect(find.text('Anime musim ini'), findsOneWidget);
    expect(find.text('A baru 1'), findsOneWidget);
  });

  testWidgets('the hero starts with the favored kind', (tester) async {
    await openHome(tester);
    expect(find.text('Tonton'), findsOneWidget);
    expect(find.text('01 / 07'), findsOneWidget);
  });

  testWidgets('the genre grid follows the favored kind', (tester) async {
    await openHome(tester);
    expect(find.text('Jelajahi genre'), findsOneWidget);
    expect(find.text('Jelajahi genre komik'), findsOneWidget);
    expect(find.text('Jelajahi genre anime'), findsNothing);
  });

  testWidgets('liking manga offers the anime genres as the extra button', (
    tester,
  ) async {
    await openHome(tester, prefersAnime: false);
    expect(find.text('Jelajahi genre anime'), findsOneWidget);
    expect(find.text('Jelajahi genre komik'), findsNothing);
  });

  testWidgets('the button for the other kind opens its genre list', (
    tester,
  ) async {
    final harness = await openHome(tester);
    await scrollDown(tester, 4000);
    await tester.tap(find.text('Jelajahi genre komik'));
    await tester.pumpAndSettle();
    expect(harness.visits.single.path, Routes.genres);
    expect(harness.visits.single.extra, MediaKindDto.manga);
  });

  testWidgets('without history there is no resume rail', (tester) async {
    await openHome(tester);
    expect(find.text('Lanjutkan'), findsNothing);
  });

  testWidgets('history of both kinds shares one resume rail', (tester) async {
    await openHome(
      tester,
      prepare: (harness) {
        harness.library.continueResult = [
          progress(MediaKindDto.anime, 'Lanjutan anime', updated: 5),
          progress(MediaKindDto.manga, 'Lanjutan manga', updated: 9, id: 78),
        ];
      },
    );
    expect(find.text('Lanjutkan'), findsOneWidget);
    expect(find.text('Lanjutan anime'), findsOneWidget);
    expect(find.text('Lanjutan manga'), findsOneWidget);
  });

  testWidgets('tapping a resume card opens the title of its own kind', (
    tester,
  ) async {
    final harness = await openHome(
      tester,
      prepare: (harness) {
        harness.library.continueResult = [
          progress(MediaKindDto.manga, 'Lanjutan manga'),
        ];
      },
    );
    await tester.tap(find.text('Lanjutan manga'));
    await tester.pumpAndSettle();
    final request = harness.visits.single.extra! as DetailRequest;
    expect(request.kind, MediaKindDto.manga);
  });

  testWidgets('the hero button opens the title with the right kind', (
    tester,
  ) async {
    final harness = await openHome(tester);
    await tester.tap(find.text('Tonton'));
    await tester.pumpAndSettle();
    expect(harness.visits.single.path, Routes.detail);
    expect(
      (harness.visits.single.extra! as DetailRequest).kind,
      MediaKindDto.anime,
    );
  });
}
