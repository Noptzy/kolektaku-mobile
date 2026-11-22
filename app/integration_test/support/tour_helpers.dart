import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/widgets/floating_dock.dart';

Future<void> openBottomTab(WidgetTester tester, String label) async {
  final finder = find.descendant(
    of: find.byType(FloatingDock),
    matching: find.text(label),
  );
  await tester.tap(finder);
  await tester.pump(const Duration(seconds: 1));
}
