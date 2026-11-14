import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/dev/gallery/sample_media.dart';
import 'package:kolektaku/widgets/hero_carousel.dart';
import 'package:kolektaku/widgets/hero_slide.dart';

import 'widget_harness.dart';

const _every = Duration(seconds: 3);

List<HeroSlide> slides(int count, {bool labelled = true}) {
  final cards = sampleCards(count);
  return [
    for (var i = 0; i < count; i++)
      HeroSlide.fromCard(
        cards[i],
        label: labelled ? 'Kategori ${i + 1}' : null,
      ),
  ];
}

Future<void> show(
  WidgetTester tester, {
  int count = 3,
  Duration? autoPlay = _every,
  bool visible = true,
}) {
  return pumpAtSize(
    tester,
    TickerMode(
      enabled: visible,
      child: HeroCarousel(slides: slides(count), autoPlay: autoPlay),
    ),
  );
}

Future<void> turn(WidgetTester tester) async {
  await tester.pump(_every);
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  group('auto play', () {
    testWidgets('moves to the next slide every interval', (tester) async {
      await show(tester);
      expect(find.text('01 / 03'), findsOneWidget);
      await turn(tester);
      expect(find.text('02 / 03'), findsOneWidget);
      await turn(tester);
      expect(find.text('03 / 03'), findsOneWidget);
    });

    testWidgets('after the last slide it goes on to the first again', (
      tester,
    ) async {
      await show(tester);
      await turn(tester);
      await turn(tester);
      await turn(tester);
      expect(find.text('01 / 03'), findsOneWidget);
      await turn(tester);
      expect(find.text('02 / 03'), findsOneWidget);
    });

    testWidgets('without an interval it stays where it is', (tester) async {
      await show(tester, autoPlay: null);
      await tester.pump(const Duration(seconds: 30));
      expect(find.text('01 / 03'), findsOneWidget);
    });

    testWidgets('a single slide has nothing to turn to', (tester) async {
      await show(tester, count: 1);
      await tester.pump(const Duration(seconds: 30));
      expect(find.text('01 / 01'), findsOneWidget);
    });

    testWidgets('holding a finger on it pauses the turning', (tester) async {
      await show(tester);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(HeroCarousel)),
      );
      await tester.pump(const Duration(seconds: 10));
      expect(find.text('01 / 03'), findsOneWidget);
      await gesture.up();
      await turn(tester);
      expect(find.text('02 / 03'), findsOneWidget);
    });

    testWidgets('a tab nobody is looking at does not turn', (tester) async {
      await show(tester, visible: false);
      await tester.pump(const Duration(seconds: 20));
      expect(find.text('01 / 03'), findsOneWidget);
    });

    testWidgets('swiping by hand still works with auto play on', (
      tester,
    ) async {
      await show(tester);
      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('02 / 03'), findsOneWidget);
    });

    testWidgets('a different number of slides restarts the timing', (
      tester,
    ) async {
      await show(tester, count: 2);
      await show(tester, count: 4);
      await turn(tester);
      expect(find.text('02 / 04'), findsOneWidget);
    });
  });

  group('slide label', () {
    testWidgets('shows the category the slide stands for', (tester) async {
      await show(tester, autoPlay: null);
      expect(find.text('Kategori 1'), findsOneWidget);
      expect(find.byKey(const Key('hero-label')), findsOneWidget);
    });

    testWidgets('a slide without a label has no label row', (tester) async {
      await pumpAtSize(
        tester,
        HeroCarousel(slides: slides(2, labelled: false)),
      );
      expect(find.byKey(const Key('hero-label')), findsNothing);
    });
  });
}
