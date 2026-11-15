import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:kolektaku/src/rust/error.dart';
import 'package:kolektaku/widgets/hero_carousel.dart';

import 'home_support.dart';

BridgeError unavailable() =>
    BridgeError(kind: BridgeErrorKind.unavailable, detail: 'x');

void main() {
  testWidgets('a failure is never retried on its own', (tester) async {
    final harness = await openHome(
      tester,
      prepare: (harness) => harness.catalog.homeError = unavailable(),
    );
    await tester.pump(const Duration(seconds: 30));
    expect(harness.catalog.homeCalls, 3);
  });

  testWidgets('when both kinds fail the page offers a retry', (tester) async {
    await openHome(
      tester,
      prepare: (harness) => harness.catalog.homeError = unavailable(),
    );
    expect(find.text('Coba lagi'), findsOneWidget);
    expect(find.byType(HeroCarousel), findsNothing);
  });

  testWidgets('one failing kind does not hide the other', (tester) async {
    await openHome(
      tester,
      prepare: (harness) => harness.catalog.onHome = (kind) async {
        if (kind == MediaKindDto.manga) throw unavailable();
        return homeOf('A');
      },
    );
    expect(find.text('Top 10 anime'), findsOneWidget);
    expect(find.text('Coba lagi'), findsNothing);
    expect(find.text('Tonton'), findsOneWidget);
  });

  testWidgets('pulling down refreshes every feed', (tester) async {
    final harness = await openHome(tester);
    expect(harness.catalog.homeCalls, 3);
    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, 400),
      1000,
    );
    await tester.pumpAndSettle();
    expect(harness.catalog.homeCalls, 6);
    expect(harness.catalog.cacheClears, 1);
  });

  testWidgets('a small phone still keeps the hero within 55 percent', (
    tester,
  ) async {
    await openHome(tester, size: const Size(360, 780));
    final height = tester.getSize(find.byType(HeroCarousel)).height;
    expect(height, lessThanOrEqualTo(780 * 0.55));
  });
}
