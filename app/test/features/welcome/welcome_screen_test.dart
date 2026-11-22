import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kolektaku/core/routes.dart';
import 'package:kolektaku/core/theme/kolektaku_theme.dart';
import 'package:kolektaku/features/welcome/welcome_copy.dart';
import 'package:kolektaku/features/welcome/welcome_gate.dart';
import 'package:kolektaku/features/welcome/welcome_providers.dart';
import 'package:kolektaku/features/welcome/welcome_screen.dart';
import 'package:kolektaku/features/welcome/welcome_store.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../widgets/widget_harness.dart';

class _Store implements WelcomeStore {
  int marks = 0;

  @override
  Future<bool> seen() async => marks > 0;

  @override
  Future<void> markSeen() async => marks++;
}

class _Opened {
  _Opened(this.store, this.gate, this.router);

  final _Store store;
  final WelcomeGate gate;
  final GoRouter router;
}

Future<_Opened> _open(
  WidgetTester tester, {
  bool pushed = false,
  Size size = phoneLarge,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  final store = _Store();
  final gate = WelcomeGate(pending: true);
  final router = GoRouter(
    initialLocation: pushed ? Routes.home : Routes.welcome,
    routes: [
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const Text('RUMAH'),
      ),
      GoRoute(
        path: Routes.welcome,
        builder: (context, state) => WelcomeScreen(gate: gate),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        welcomeStoreProvider.overrideWithValue(store),
        welcomeCoversProvider.overrideWith((ref) async => <String>[]),
      ],
      child: ShadApp.router(
        darkTheme: kolektakuDarkTheme(),
        themeMode: ThemeMode.dark,
        routerConfig: router,
      ),
    ),
  );
  if (pushed) {
    router.push(Routes.welcome);
  }
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  return _Opened(store, gate, router);
}

Future<void> _toLastPage(WidgetTester tester) async {
  for (var i = 0; i < welcomePages.length - 1; i++) {
    await tester.tap(find.byKey(const Key('welcome-next')));
    await tester.pumpAndSettle();
  }
}

double _skipOpacity(WidgetTester tester) => tester
    .widget<AnimatedOpacity>(
      find.ancestor(
        of: find.byKey(const Key('welcome-skip')),
        matching: find.byType(AnimatedOpacity),
      ),
    )
    .opacity;

void main() {
  testWidgets('opens on the first page with the brand, skip and next', (
    tester,
  ) async {
    await _open(tester);
    expect(find.text(welcomeBrandName), findsOneWidget);
    expect(find.text(welcomePages.first.title), findsOneWidget);
    expect(find.text(welcomePages.first.body), findsOneWidget);
    expect(find.text('Lewati'), findsOneWidget);
    expect(find.text('Lanjut'), findsOneWidget);
  });

  testWidgets('next moves to the following page', (tester) async {
    await _open(tester);
    await tester.tap(find.byKey(const Key('welcome-next')));
    await tester.pumpAndSettle();
    expect(find.text(welcomePages[1].title), findsOneWidget);
    expect(find.text(welcomePages.first.title), findsNothing);
  });

  testWidgets('swiping also changes the page', (tester) async {
    await _open(tester);
    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text(welcomePages[1].title), findsOneWidget);
  });

  testWidgets(
    'skip is there on every page but the last, where start replaces next',
    (tester) async {
      await _open(tester);
      expect(_skipOpacity(tester), 1);
      await _toLastPage(tester);
      expect(find.text(welcomePages.last.title), findsOneWidget);
      expect(find.text('Mulai'), findsOneWidget);
      expect(find.text('Lanjut'), findsNothing);
      expect(_skipOpacity(tester), 0);
    },
  );

  testWidgets('skip remembers it was seen and goes home', (tester) async {
    final opened = await _open(tester);
    await tester.tap(find.byKey(const Key('welcome-skip')));
    await tester.pumpAndSettle();
    expect(opened.store.marks, 1);
    expect(opened.gate.pending, isFalse);
    expect(find.text('RUMAH'), findsOneWidget);
  });

  testWidgets('start on the last page does the same', (tester) async {
    final opened = await _open(tester);
    await _toLastPage(tester);
    await tester.tap(find.byKey(const Key('welcome-next')));
    await tester.pumpAndSettle();
    expect(opened.store.marks, 1);
    expect(opened.gate.pending, isFalse);
    expect(find.text('RUMAH'), findsOneWidget);
  });

  testWidgets('seen again on purpose, it goes back to where it came from', (
    tester,
  ) async {
    final opened = await _open(tester, pushed: true);
    expect(find.text(welcomePages.first.title), findsOneWidget);
    await tester.tap(find.byKey(const Key('welcome-skip')));
    await tester.pumpAndSettle();
    expect(find.text('RUMAH'), findsOneWidget);
    expect(opened.router.canPop(), isFalse);
  });

  testWidgets('the main button is at least 48 dp tall', (tester) async {
    await _open(tester);
    final size = tester.getSize(find.byKey(const Key('welcome-next')));
    expect(size.height, greaterThanOrEqualTo(48));
  });

  testWidgets('every page fits the small phone without overflow', (
    tester,
  ) async {
    await _open(tester, size: phoneSmall);
    for (var i = 0; i < welcomePages.length; i++) {
      expect(tester.takeException(), isNull, reason: 'page $i');
      if (i < welcomePages.length - 1) {
        await tester.tap(find.byKey(const Key('welcome-next')));
        await tester.pumpAndSettle();
      }
    }
  });

  testWidgets('large text still fits every page', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await _open(tester, size: phoneSmall);
    for (var i = 0; i < welcomePages.length; i++) {
      expect(tester.takeException(), isNull, reason: 'page $i');
      if (i < welcomePages.length - 1) {
        await tester.tap(find.byKey(const Key('welcome-next')));
        await tester.pumpAndSettle();
      }
    }
  });

  test(
    'no page claims the code is open until there is a license to back it',
    () {
      for (final page in welcomePages) {
        final text = '${page.title} ${page.body}'.toLowerCase();
        expect(text, isNot(contains('terbuka')), reason: page.title);
        expect(text, isNot(contains('open source')), reason: page.title);
      }
    },
  );

  test('the copy is complete and in Indonesian', () {
    expect(welcomePages, hasLength(5));
    for (final page in welcomePages) {
      expect(page.title.trim(), isNotEmpty);
      expect(page.body.trim(), isNotEmpty);
      expect(page.title, endsWith('.'));
    }
  });
}
