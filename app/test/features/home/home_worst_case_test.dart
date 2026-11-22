import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/home/home_sections.dart';
import 'package:kolektaku/features/dev/gallery/sample_media.dart';
import 'package:kolektaku/src/rust/dto/cards.dart';
import 'package:kolektaku/widgets/hero_carousel.dart';
import 'package:kolektaku/widgets/hero_counter.dart';
import 'package:kolektaku/widgets/hero_slide.dart';
import 'package:kolektaku/widgets/media_card.dart';
import 'package:kolektaku/widgets/media_meta.dart';

import '../../widgets/widget_harness.dart';
import 'home_support.dart';

HomeDto _emptyHome() => const HomeDto(
  sections: [
    HomeSectionDto(id: 'trending', cards: []),
    HomeSectionDto(id: 'latest', cards: []),
    HomeSectionDto(id: 'popular', cards: []),
  ],
  notices: [],
);

void main() {
  group('a home with nothing to show', () {
    test('homeIsEmpty is true when every section of every kind is empty', () {
      expect(
        homeIsEmpty(
          anime: _emptyHome(),
          manga: _emptyHome(),
          novel: null,
          hasResume: false,
        ),
        isTrue,
      );
    });

    test('a single card or a resume entry makes it not empty', () {
      expect(
        homeIsEmpty(
          anime: homeOf('A'),
          manga: _emptyHome(),
          novel: null,
          hasResume: false,
        ),
        isFalse,
      );
      expect(
        homeIsEmpty(
          anime: _emptyHome(),
          manga: _emptyHome(),
          novel: null,
          hasResume: true,
        ),
        isFalse,
      );
    });

    testWidgets('the page says so and offers a retry instead of going blank', (
      tester,
    ) async {
      await openHome(
        tester,
        prepare: (harness) =>
            harness.catalog.onHome = (kind) async => _emptyHome(),
      );
      expect(find.text('Beranda masih kosong'), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
      expect(find.byType(HeroCarousel), findsNothing);
    });

    testWidgets('retrying asks the catalog again', (tester) async {
      final harness = await openHome(
        tester,
        prepare: (harness) =>
            harness.catalog.onHome = (kind) async => _emptyHome(),
      );
      final before = harness.catalog.homeCalls;
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      expect(harness.catalog.homeCalls, greaterThan(before));
    });
  });

  group('the hero counter', () {
    testWidgets('a single slide has no counter to count', (tester) async {
      await pumpAtSize(
        tester,
        HeroCarousel(slides: [HeroSlide.fromCard(sampleCard(1))]),
      );
      expect(find.text('01 / 01'), findsNothing);
      expect(find.byType(HeroCounter), findsNothing);
      expect(find.text('Tonton'), findsOneWidget);
    });

    test('is shown only when there is more than one slide', () {
      expect(HeroCarousel.showsCounter(1), isFalse);
      expect(HeroCarousel.showsCounter(2), isTrue);
      expect(HeroCarousel.showsCounter(7), isTrue);
    });
  });

  group('titles that stress a poster card', () {
    testWidgets('a long tag such as an OVA special stays inside the poster', (
      tester,
    ) async {
      await pumpAtSize(
        tester,
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 112,
            child: MediaCard(
              card: sampleCard(1, title: 'Judul'),
              tag: 'Ep 24.5 · OVA Final',
            ),
          ),
        ),
        size: phoneSmall,
      );
      expect(tester.takeException(), isNull);
      final poster = tester.getRect(find.byType(MediaCard));
      final tag = tester.getRect(find.text('Ep 24.5 · OVA Final'));
      expect(tag.right, lessThanOrEqualTo(poster.right));
    });

    test('a missing year never leaves a lonely separator', () {
      final card = MediaCardDto(
        reference: sampleCard(1).reference,
        title: 'Tanpa tahun',
        unitCount: 12,
        genres: const [],
        limited: false,
        sources: const [],
      );
      expect(mediaMeta(card), '12 eps');
      expect(mediaMeta(card), isNot(startsWith('·')));
      expect(mediaMeta(card), isNot(endsWith('·')));
    });

    test('a missing unit count leaves just the year', () {
      final card = MediaCardDto(
        reference: sampleCard(1).reference,
        title: 'Tanpa jumlah',
        year: 2026,
        genres: const [],
        limited: false,
        sources: const [],
      );
      expect(mediaMeta(card), '2026');
    });
  });
}
