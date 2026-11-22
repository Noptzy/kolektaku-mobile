import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/welcome/welcome_dots.dart';

import '../../widgets/widget_harness.dart';

double _width(WidgetTester tester, int i) =>
    tester.getSize(find.byKey(Key('welcome-dot-$i'))).width;

void main() {
  testWidgets('one dot per page, the current one is the wide one', (
    tester,
  ) async {
    await pumpAtSize(
      tester,
      const Align(
        alignment: Alignment.topLeft,
        child: WelcomeDots(count: 5, index: 2),
      ),
    );
    await tester.pumpAndSettle();
    for (var i = 0; i < 5; i++) {
      expect(find.byKey(Key('welcome-dot-$i')), findsOneWidget);
    }
    expect(_width(tester, 2), 20);
    expect(_width(tester, 0), 6);
    expect(_width(tester, 4), 6);
  });

  testWidgets('moving on grows the next dot and shrinks the old one', (
    tester,
  ) async {
    Widget dots(int index) => Align(
      alignment: Alignment.topLeft,
      child: WelcomeDots(count: 5, index: index),
    );
    await pumpAtSize(tester, dots(0));
    await tester.pumpAndSettle();
    await pumpAtSize(tester, dots(1));
    await tester.pumpAndSettle();
    expect(_width(tester, 1), 20);
    expect(_width(tester, 0), 6);
  });

  testWidgets('is announced as a single page indicator', (tester) async {
    await pumpAtSize(
      tester,
      const Align(
        alignment: Alignment.topLeft,
        child: WelcomeDots(count: 5, index: 1),
      ),
    );
    expect(find.bySemanticsLabel('Halaman 2 dari 5'), findsOneWidget);
  });

  testWidgets('with animations off the change is immediate', (tester) async {
    Widget dots(int index) => MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: Align(
        alignment: Alignment.topLeft,
        child: WelcomeDots(count: 3, index: index),
      ),
    );
    await pumpAtSize(tester, dots(0));
    await pumpAtSize(tester, dots(2));
    await tester.pump();
    expect(_width(tester, 2), 20);
  });
}
