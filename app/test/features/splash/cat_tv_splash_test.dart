import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/splash/cat_tv_splash.dart';

Widget host({bool reduced = false, String label = 'kolektaku'}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: MediaQueryData(
        size: const Size(390, 844),
        disableAnimations: reduced,
      ),
      child: CatTvSplash(label: label),
    ),
  );
}

void main() {
  testWidgets('the cat, the television and the name are on screen', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    expect(find.byKey(const Key('splash-cat')), findsOneWidget);
    expect(find.byKey(const Key('splash-tv')), findsOneWidget);
    expect(find.text('kolektaku'), findsOneWidget);
  });

  testWidgets('the label can be changed', (tester) async {
    await tester.pumpWidget(host(label: 'Menyiapkan'));
    expect(find.text('Menyiapkan'), findsOneWidget);
  });

  testWidgets('the scene keeps moving while it is shown', (tester) async {
    await tester.pumpWidget(host());
    final before = tester.widget<CustomPaint>(
      find.byKey(const Key('splash-tv')),
    );
    await tester.pump(const Duration(milliseconds: 500));
    final after = tester.widget<CustomPaint>(
      find.byKey(const Key('splash-tv')),
    );
    expect(before.painter!.shouldRepaint(after.painter!), isTrue);
    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets('with reduced motion the scene is one still frame', (
    tester,
  ) async {
    await tester.pumpWidget(host(reduced: true));
    await tester.pump(const Duration(seconds: 2));
    expect(tester.hasRunningAnimations, isFalse);
    expect(find.byKey(const Key('splash-tv')), findsOneWidget);
  });

  testWidgets('turning motion back on starts the scene again', (tester) async {
    await tester.pumpWidget(host(reduced: true));
    expect(tester.hasRunningAnimations, isFalse);
    await tester.pumpWidget(host());
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets('leaving the screen stops its clock', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.hasRunningAnimations, isFalse);
  });
}
