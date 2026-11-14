import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/widgets/app_bottom_bar.dart';

Future<void> openBottomTab(WidgetTester tester, String label) async {
  final finder = find.descendant(
    of: find.byType(AppBottomBar),
    matching: find.text(label),
  );
  await tester.tap(finder);
  await tester.pump(const Duration(seconds: 1));
}
