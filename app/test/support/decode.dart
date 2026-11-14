import 'package:flutter_test/flutter_test.dart';

Future<void> decoded(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 80)),
  );
  await tester.pump();
}
