import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/widgets/refresh_on_visible.dart';

Widget tab({required bool visible, required VoidCallback onVisible}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: TickerMode(
      enabled: visible,
      child: RefreshOnVisible(onVisible: onVisible, child: const SizedBox()),
    ),
  );
}

void main() {
  group('RefreshOnVisible', () {
    testWidgets('does nothing on the first build, visible or not', (
      tester,
    ) async {
      var calls = 0;
      await tester.pumpWidget(tab(visible: true, onVisible: () => calls++));
      await tester.pump();
      expect(calls, 0);
    });

    testWidgets('fires once each time a hidden tab comes back', (tester) async {
      var calls = 0;
      void bump() => calls++;
      await tester.pumpWidget(tab(visible: true, onVisible: bump));
      await tester.pumpWidget(tab(visible: false, onVisible: bump));
      await tester.pump();
      expect(calls, 0);
      await tester.pumpWidget(tab(visible: true, onVisible: bump));
      await tester.pump();
      expect(calls, 1);
      await tester.pumpWidget(tab(visible: false, onVisible: bump));
      await tester.pumpWidget(tab(visible: true, onVisible: bump));
      await tester.pump();
      expect(calls, 2);
    });

    testWidgets('a rebuild that changes nothing does not fire', (tester) async {
      var calls = 0;
      void bump() => calls++;
      await tester.pumpWidget(tab(visible: false, onVisible: bump));
      await tester.pumpWidget(tab(visible: false, onVisible: bump));
      await tester.pump();
      expect(calls, 0);
    });
  });
}
