import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/dev/gallery/sample_media.dart';
import 'package:kolektaku/src/rust/dto/cards.dart';
import 'package:kolektaku/widgets/hero_carousel.dart';
import 'package:kolektaku/widgets/hero_slide.dart';
import 'package:kolektaku/widgets/hero_slide_view.dart';

import 'widget_harness.dart';

List<HeroSlide> slides(int count) {
  final cards = sampleCards(count);
  return [
    for (var i = 0; i < count; i++)
      HeroSlide.fromCard(cards[i], hasTrailer: i == 0),
  ];
}

void main() {
  group('HeroCarousel helpers', () {
    test('the counter pads to two digits', () {
      expect(HeroCarousel.counter(0, 8), '01 / 08');
      expect(HeroCarousel.counter(9, 12), '10 / 12');
    });

    test('the height never passes 55 percent of the screen', () {
      expect(HeroCarousel.heightFor(phoneLarge), lessThanOrEqualTo(844 * 0.55));
      expect(HeroCarousel.heightFor(phoneSmall), lessThanOrEqualTo(780 * 0.55));
    });

    test('the height makes room for the poster, synopsis and buttons', () {
      expect(HeroCarousel.heightFor(phoneLarge), closeTo(345, 2));
    });

    test('the status bar inset is added on top', () {
      final plain = HeroCarousel.heightFor(phoneLarge);
      expect(HeroCarousel.heightFor(phoneLarge, inset: 30) - plain, 30);
    });

    test('a short screen caps the height at 55 percent', () {
      expect(HeroCarousel.heightFor(const Size(390, 400)), 400 * 0.55);
    });

    test('a wide screen stops growing the poster', () {
      expect(
        HeroCarousel.heightFor(const Size(1000, 4000)),
        HeroCarousel.heightFor(const Size(2000, 4000)),
      );
    });

    test('bigger system text asks for more room until the cap', () {
      final plain = HeroCarousel.heightFor(phoneLarge);
      final large = HeroCarousel.heightFor(
        phoneLarge,
        scaler: const TextScaler.linear(1.5),
      );
      expect(large, greaterThan(plain));
      expect(large, lessThanOrEqualTo(844 * 0.55));
    });

    test('the poster is a third of the width but never wider than 130', () {
      expect(heroPosterWidth(390), closeTo(117, 0.01));
      expect(heroPosterWidth(2000), 130);
    });
  });

  group('HeroSlide', () {
    test('builds the info line from year, format and first genre', () {
      expect(HeroSlide.fromCard(sampleCard(1)).meta, '2016 · TV · Aksi');
    });

    test('prefers the sharp cover and keeps the synopsis', () {
      final card = sampleCard(1);
      final slide = HeroSlide.fromCard(
        MediaCardDto(
          reference: card.reference,
          title: card.title,
          coverUrl: 'small',
          coverHdUrl: 'sharp',
          synopsis: 'Ringkasan.',
          genres: card.genres,
          limited: false,
          sources: const [],
        ),
      );
      expect(slide.imageUrl, 'sharp');
      expect(slide.synopsis, 'Ringkasan.');
    });

    test('falls back to the card cover when there is no sharp one', () {
      final card = sampleCard(1);
      final slide = HeroSlide.fromCard(
        MediaCardDto(
          reference: card.reference,
          title: card.title,
          coverUrl: 'small',
          genres: card.genres,
          limited: false,
          sources: const [],
        ),
      );
      expect(slide.imageUrl, 'small');
      expect(slide.synopsis, isNull);
    });

    test('keeps the score and the trailer flag', () {
      final slide = HeroSlide.fromCard(sampleCard(1), hasTrailer: true);
      expect(slide.score, 8.6);
      expect(slide.hasTrailer, isTrue);
    });
  });

  group('HeroCarousel', () {
    testWidgets('shows the first slide with the counter', (tester) async {
      await pumpAtSize(tester, HeroCarousel(slides: slides(8)));
      expect(find.text('01 / 08'), findsOneWidget);
      expect(find.text('Tonton'), findsOneWidget);
      expect(find.text('Simpan'), findsOneWidget);
      expect(find.text('Trailer'), findsOneWidget);
    });

    testWidgets('swiping moves the counter and hides a missing trailer', (
      tester,
    ) async {
      await pumpAtSize(tester, HeroCarousel(slides: slides(3)));
      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('02 / 03'), findsOneWidget);
      expect(find.text('Trailer'), findsNothing);
    });

    testWidgets('buttons report the index of the visible slide', (
      tester,
    ) async {
      final watched = <int>[];
      final saved = <int>[];
      await pumpAtSize(
        tester,
        HeroCarousel(
          slides: slides(3),
          onWatch: watched.add,
          onSave: saved.add,
        ),
      );
      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tonton'));
      await tester.tap(find.text('Simpan'));
      expect(watched, [1]);
      expect(saved, [1]);
    });

    testWidgets('each slide shows its short synopsis', (tester) async {
      await pumpAtSize(tester, HeroCarousel(slides: slides(3)));
      final text = tester.widget<Text>(find.byKey(const Key('hero-synopsis')));
      expect(text.data, sampleSynopsis);
      expect(text.maxLines, heroSynopsisLines);
    });

    testWidgets('a slide without a synopsis shows none and still fits', (
      tester,
    ) async {
      final card = sampleCard(1, withSynopsis: false);
      await pumpAtSize(
        tester,
        HeroCarousel(slides: [HeroSlide.fromCard(card)]),
      );
      expect(find.byKey(const Key('hero-synopsis')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('large system text does not overflow the slide', (
      tester,
    ) async {
      await pumpAtSize(
        tester,
        MediaQuery(
          data: const MediaQueryData(
            size: phoneSmall,
            textScaler: TextScaler.linear(1.6),
          ),
          child: HeroCarousel(slides: slides(2)),
        ),
        size: phoneSmall,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('no slides renders nothing', (tester) async {
      await pumpAtSize(tester, const HeroCarousel(slides: []));
      expect(find.byType(PageView), findsNothing);
    });
  });
}
