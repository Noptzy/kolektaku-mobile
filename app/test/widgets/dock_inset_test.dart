import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/theme/glass_tokens.dart';
import 'package:kolektaku/widgets/dock_inset.dart';

import 'widget_harness.dart';

void main() {
  test('clearance sits above the dock with a gap', () {
    expect(
      DockMetrics.clearance(0),
      DockMetrics.gapAboveSystem + DockMetrics.height + DockMetrics.contentGap,
    );
    expect(DockMetrics.clearance(24) - DockMetrics.clearance(0), 24);
  });

  testWidgets('outside the shell there is no inset', (tester) async {
    late double seen;
    await pumpAtSize(
      tester,
      Align(
        alignment: Alignment.topLeft,
        child: Builder(
          builder: (context) {
            seen = DockInset.of(context);
            return const DockSpace();
          },
        ),
      ),
    );
    expect(seen, 0);
    expect(tester.getSize(find.byType(DockSpace)).height, 0);
  });

  testWidgets('space reserves the clearance plus any extra', (tester) async {
    await pumpAtSize(
      tester,
      const Align(
        alignment: Alignment.topLeft,
        child: DockInset(clearance: 100, child: DockSpace(extra: 8)),
      ),
    );
    expect(tester.getSize(find.byType(DockSpace)).height, 108);
  });
}
