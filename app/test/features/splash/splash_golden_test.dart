import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/splash/cat_tv_splash.dart';

Future<void> frame(WidgetTester tester, int millis) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(size: Size(390, 844)),
        child: RepaintBoundary(
          key: const Key('frame'),
          child: const CatTvSplash(),
        ),
      ),
    ),
  );
  await tester.runAsync(() async {
    final context = tester.element(find.byType(CatTvSplash));
    await precacheImage(const AssetImage(catAsset), context);
  });
  await tester.pump(Duration(milliseconds: millis));
  await tester.pump();
}

void main() {
  for (final entry in {'blue': 450, 'snow': 850, 'green': 1700}.entries) {
    testWidgets('splash frame ${entry.key}', (tester) async {
      await frame(tester, entry.value);
      await expectLater(
        find.byKey(const Key('frame')),
        matchesGoldenFile('goldens/splash_${entry.key}.png'),
      );
    });
  }
}
