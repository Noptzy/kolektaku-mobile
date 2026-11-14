import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/routes.dart';
import 'package:kolektaku/features/detail/detail_request.dart';
import 'package:kolektaku/src/rust/dto/media.dart';

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
    expect(find.text('01 / 08'), findsOneWidget);
    expect(find.text('Tonton'), findsOneWidget);
  });

  testWidgets('both kinds get their own rails', (tester) async {
    await openHome(tester);
    for (final title in [
      'Top 10 anime',
      'Episode baru',
      'Top 10 komik',
      'Chapter baru',
      'Anime musim ini',
      'Anime populer',
      'Komik populer',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
  });

  testWidgets('liking anime puts the anime rails above the manga rails', (
    tester,
  ) async {
    await openHome(tester);
    final anime = tester.getTopLeft(find.text('Top 10 anime')).dy;
    final manga = tester.getTopLeft(find.text('Top 10 komik')).dy;
    expect(anime, lessThan(manga));
    final latestAnime = tester.getTopLeft(find.text('Episode baru')).dy;
    expect(latestAnime, lessThan(manga));
  });

  testWidgets('liking manga puts the manga rails above the anime rails', (
    tester,
  ) async {
    await openHome(tester, prefersAnime: false);
    final anime = tester.getTopLeft(find.text('Top 10 anime')).dy;
    final manga = tester.getTopLeft(find.text('Top 10 komik')).dy;
    expect(manga, lessThan(anime));
    expect(find.text('Baca'), findsOneWidget);
    expect(find.text('Tonton'), findsNothing);
  });

  testWidgets('the hero starts with the favored kind', (tester) async {
    await openHome(tester);
    expect(find.text('Tonton'), findsOneWidget);
    expect(find.text('01 / 08'), findsOneWidget);
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
