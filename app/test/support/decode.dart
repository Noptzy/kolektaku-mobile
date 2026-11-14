import 'package:flutter_test/flutter_test.dart';

const _step = Duration(milliseconds: 40);
const _limit = Duration(seconds: 5);

Future<void> decoded(WidgetTester tester, {bool Function()? until}) async {
  if (until == null) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 80)),
    );
    await tester.pump();
    return;
  }
  final waited = Stopwatch()..start();
  while (waited.elapsed < _limit) {
    await tester.runAsync(() => Future<void>.delayed(_step));
    await tester.pump();
    if (until()) return;
  }
}
