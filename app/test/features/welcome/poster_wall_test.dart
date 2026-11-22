import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/welcome/poster_wall.dart';
import 'package:kolektaku/features/welcome/poster_wall_columns.dart';
import 'package:kolektaku/features/welcome/welcome_providers.dart';
import 'package:kolektaku/widgets/poster.dart';

import '../../widgets/widget_harness.dart';

Widget _wall({List<String> covers = const []}) => ProviderScope(
  overrides: [welcomeCoversProvider.overrideWith((ref) async => covers)],
  child: const SizedBox.expand(child: PosterWall()),
);

Widget _still(Widget child) => MediaQuery(
  data: const MediaQueryData(disableAnimations: true),
  child: child,
);

void main() {
  testWidgets('draws every column even with no covers to show', (tester) async {
    await pumpAtSize(tester, _still(_wall()));
    await tester.pump();
    expect(
      find.byType(Poster),
      findsNWidgets(wallColumns * wallTilesPerColumn * 2),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps drifting while animations are allowed', (tester) async {
    await pumpAtSize(tester, _wall());
    await tester.pump();
    final first = tester.getTopLeft(find.byType(Poster).first);
    await tester.pump(const Duration(seconds: 10));
    expect(tester.getTopLeft(find.byType(Poster).first), isNot(first));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('stands still when animations are disabled', (tester) async {
    await pumpAtSize(tester, _still(_wall()));
    await tester.pump();
    final first = tester.getTopLeft(find.byType(Poster).first);
    await tester.pump(const Duration(seconds: 10));
    expect(tester.getTopLeft(find.byType(Poster).first), first);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('never takes touches and is invisible to screen readers', (
    tester,
  ) async {
    await pumpAtSize(tester, _still(_wall()));
    await tester.pump();
    final ignoring = tester.widgetList<IgnorePointer>(
      find.descendant(
        of: find.byType(PosterWall),
        matching: find.byType(IgnorePointer),
      ),
    );
    expect(ignoring.any((widget) => widget.ignoring), isTrue);
    expect(
      find.descendant(
        of: find.byType(PosterWall),
        matching: find.byType(ExcludeSemantics),
      ),
      findsWidgets,
    );
  });

  testWidgets('a failing cover feed just leaves the plain tiles', (
    tester,
  ) async {
    await pumpAtSize(
      tester,
      _still(
        ProviderScope(
          overrides: [
            welcomeCoversProvider.overrideWith(
              (ref) async => throw StateError('x'),
            ),
          ],
          child: const SizedBox.expand(child: PosterWall()),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(Poster), findsWidgets);
  });
}
