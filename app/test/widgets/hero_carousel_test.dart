import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/dev/gallery/sample_media.dart';
import 'package:kolektaku/widgets/hero_carousel.dart';
import 'package:kolektaku/widgets/hero_slide.dart';

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

    test('a wide screen is capped, a narrow one keeps its ratio', () {
      expect(HeroCarousel.heightFor(const Size(300, 2000)), 360);
      expect(HeroCarousel.heightFor(const Size(1000, 600)), 330);
    });
  });

  group('HeroSlide', () {
    test('builds the info line from year, format and first genre', () {
      expect(HeroSlide.fromCard(sampleCard(1)).meta, '2016 · TV · Aksi');
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

    testWidgets('no slides renders nothing', (tester) async {
      await pumpAtSize(tester, const HeroCarousel(slides: []));
      expect(find.byType(PageView), findsNothing);
    });
  });
}
