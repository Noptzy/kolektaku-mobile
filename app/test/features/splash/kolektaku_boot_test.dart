import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/splash/cat_tv_splash.dart';
import 'package:kolektaku/features/splash/kolektaku_boot.dart';

Widget boot({
  required BootStep init,
  Duration minimum = const Duration(milliseconds: 600),
}) {
  return KolektakuBoot(
    init: init,
    minimum: minimum,
    app: (context) => const Directionality(
      textDirection: TextDirection.ltr,
      child: Text('app terbuka', key: Key('app')),
    ),
  );
}

void main() {
  testWidgets('the splash shows first and the app opens once ready', (
    tester,
  ) async {
    await tester.pumpWidget(boot(init: () async {}));
    expect(find.byType(CatTvSplash), findsOneWidget);
    expect(find.byKey(const Key('app')), findsNothing);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('app')), findsOneWidget);
    expect(find.byType(CatTvSplash), findsNothing);
  });

  testWidgets('a fast start still lets the animation play for a moment', (
    tester,
  ) async {
    await tester.pumpWidget(boot(init: () async {}));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(CatTvSplash), findsOneWidget);
    expect(find.byKey(const Key('app')), findsNothing);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets('a slow start keeps the splash until it finishes', (
    tester,
  ) async {
    final hold = Completer<void>();
    await tester.pumpWidget(boot(init: () => hold.future));
    await tester.pump(const Duration(seconds: 5));
    expect(find.byType(CatTvSplash), findsOneWidget);
    hold.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('app')), findsOneWidget);
  });

  testWidgets('the app fades in instead of popping up', (tester) async {
    await tester.pumpWidget(boot(init: () async {}));
    await tester.pump(const Duration(milliseconds: 650));
    final fade = tester.widget<FadeTransition>(find.byType(FadeTransition));
    expect(fade.opacity.value, lessThan(1));
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      tester.widget<FadeTransition>(find.byType(FadeTransition)).opacity.value,
      1,
    );
  });

  testWidgets('a failing start says so and offers a retry', (tester) async {
    await tester.pumpWidget(
      boot(init: () async => throw StateError('no core')),
    );
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byKey(const Key('boot-failed')), findsOneWidget);
    expect(find.text('Aplikasi belum bisa dimulai.'), findsOneWidget);
    expect(find.byType(CatTvSplash), findsNothing);
    expect(find.byKey(const Key('app')), findsNothing);
  });

  testWidgets('the retry runs the start again and opens the app', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      boot(
        init: () async {
          attempts++;
          if (attempts == 1) throw StateError('no core');
        },
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));
    await tester.tap(find.byKey(const Key('boot-retry')));
    await tester.pump();
    expect(find.byType(CatTvSplash), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 400));
    expect(attempts, 2);
    expect(find.byKey(const Key('app')), findsOneWidget);
  });

  testWidgets('with reduced motion nothing waits for the animation', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(boot(init: () async {}));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('app')), findsOneWidget);
  });

  testWidgets('leaving before the start ends is harmless', (tester) async {
    final hold = Completer<void>();
    await tester.pumpWidget(boot(init: () => hold.future));
    await tester.pumpWidget(const SizedBox());
    hold.complete();
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });
}
