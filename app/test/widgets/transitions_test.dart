import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kolektaku/core/page_transitions.dart';
import 'package:kolektaku/widgets/fade_branches.dart';

Widget appOver(GoRouter router, {bool reduced = false}) {
  return MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: WidgetsApp.router(
      color: const Color(0xFF000000),
      routerConfig: router,
    ),
  );
}

GoRouter routerWith(PageMotion motion) {
  return GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const Text('home')),
      GoRoute(
        path: '/next',
        pageBuilder: (context, state) =>
            motionPage(state: state, motion: motion, child: const Text('next')),
      ),
    ],
  );
}

void main() {
  group('motionPage', () {
    testWidgets('a pushed page slides and fades in, then settles', (
      tester,
    ) async {
      final router = routerWith(PageMotion.slide);
      await tester.pumpWidget(appOver(router));
      router.push('/next');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final slide = find.ancestor(
        of: find.text('next'),
        matching: find.byType(SlideTransition),
      );
      expect(slide, findsWidgets);
      final fade = tester.widget<FadeTransition>(
        find
            .ancestor(
              of: find.text('next'),
              matching: find.byType(FadeTransition),
            )
            .first,
      );
      expect(fade.opacity.value, inExclusiveRange(0, 1));
      await tester.pumpAndSettle();
      expect(find.text('next'), findsOneWidget);
    });

    testWidgets('the fade motion has no slide', (tester) async {
      final router = routerWith(PageMotion.fade);
      await tester.pumpWidget(appOver(router));
      router.push('/next');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.ancestor(
          of: find.text('next'),
          matching: find.byType(SlideTransition),
        ),
        findsNothing,
      );
      expect(
        find.ancestor(
          of: find.text('next'),
          matching: find.byType(FadeTransition),
        ),
        findsWidgets,
      );
      await tester.pumpAndSettle();
    });

    testWidgets('reduced motion opens the page without animating it', (
      tester,
    ) async {
      final router = routerWith(PageMotion.slide);
      await tester.pumpWidget(appOver(router, reduced: true));
      router.push('/next');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(
        find.ancestor(
          of: find.text('next'),
          matching: find.byType(SlideTransition),
        ),
        findsNothing,
      );
      await tester.pumpAndSettle();
    });

    testWidgets('going back plays the exit and removes the page', (
      tester,
    ) async {
      final router = routerWith(PageMotion.slide);
      await tester.pumpWidget(appOver(router));
      router.push('/next');
      await tester.pumpAndSettle();
      router.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('next'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('next'), findsNothing);
    });
  });

  group('FadeBranches', () {
    Widget host(int index, {bool reduced = false}) {
      return MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: FadeBranches(
            index: index,
            children: const [Text('one'), Text('two'), Text('three')],
          ),
        ),
      );
    }

    testWidgets('only the current branch shows at rest', (tester) async {
      await tester.pumpWidget(host(0));
      expect(find.text('one'), findsOneWidget);
      expect(find.text('two', skipOffstage: false), findsOneWidget);
      expect(find.text('two'), findsNothing);
    });

    testWidgets('both branches show while one fades into the other', (
      tester,
    ) async {
      await tester.pumpWidget(host(0));
      await tester.pumpWidget(host(1));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('one'), findsOneWidget);
      expect(find.text('two'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('one'), findsNothing);
      expect(find.text('two'), findsOneWidget);
    });

    testWidgets('every branch stays alive while it is hidden', (tester) async {
      await tester.pumpWidget(host(0));
      await tester.pumpWidget(host(2));
      await tester.pumpAndSettle();
      expect(find.text('one', skipOffstage: false), findsOneWidget);
      expect(find.text('two', skipOffstage: false), findsOneWidget);
    });

    testWidgets('reduced motion switches at once', (tester) async {
      await tester.pumpWidget(host(0, reduced: true));
      await tester.pumpWidget(host(1, reduced: true));
      await tester.pump();
      expect(find.text('one'), findsNothing);
      expect(find.text('two'), findsOneWidget);
    });

    testWidgets('a hidden branch ignores touches', (tester) async {
      await tester.pumpWidget(host(0));
      final hidden = tester.widget<IgnorePointer>(
        find
            .ancestor(
              of: find.text('two', skipOffstage: false),
              matching: find.byType(IgnorePointer, skipOffstage: false),
            )
            .first,
      );
      expect(hidden.ignoring, isTrue);
    });
  });
}
