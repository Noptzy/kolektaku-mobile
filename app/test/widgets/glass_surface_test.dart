import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/theme/glass_tokens.dart';
import 'package:kolektaku/widgets/glass_budget.dart';
import 'package:kolektaku/widgets/glass_surface.dart';

import 'widget_harness.dart';

const _surface = GlassSurface(
  radius: BorderRadius.all(Radius.circular(32)),
  child: SizedBox(width: 200, height: 64),
);

void main() {
  testWidgets('blurs what is behind it by default', (tester) async {
    await pumpAtSize(tester, _surface);
    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('falls back to a solid surface in high contrast', (tester) async {
    await pumpAtSize(
      tester,
      MediaQuery(
        data: const MediaQueryData(highContrast: true),
        child: _surface,
      ),
    );
    expect(find.byType(BackdropFilter), findsNothing);
    final box = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(GlassSurface),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect((box.decoration as BoxDecoration).color, Glass.solid);
  });

  testWidgets('drops the blur once the frame budget trips', (tester) async {
    final budget = GlassBudget();
    await pumpAtSize(tester, GlassBudgetHost(budget: budget, child: _surface));
    expect(find.byType(BackdropFilter), findsOneWidget);

    budget.record(List.filled(glassWindowFrames * 2, 40.0));
    await tester.pump();
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('keeps its child laid out the same with or without blur', (
    tester,
  ) async {
    final budget = GlassBudget();
    await pumpAtSize(tester, GlassBudgetHost(budget: budget, child: _surface));
    final blurred = tester.getSize(find.byType(GlassSurface));
    budget.record(List.filled(glassWindowFrames * 2, 40.0));
    await tester.pump();
    expect(tester.getSize(find.byType(GlassSurface)), blurred);
  });
}
