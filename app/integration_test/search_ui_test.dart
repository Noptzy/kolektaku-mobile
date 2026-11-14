import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kolektaku/app.dart';
import 'package:kolektaku/app_scope.dart';
import 'package:kolektaku/core/router.dart';
import 'package:kolektaku/core/routes.dart';
import 'package:kolektaku/data/core_session.dart';
import 'package:kolektaku/src/rust/frb_generated.dart';

import 'support/watch_driver.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await RustLib.init();
    await startCore();
  });

  testWidgets('a misspelled title still lists Kimi no Na wa.', (tester) async {
    await tester.pumpWidget(kolektakuScope(child: const KolektakuApp()));
    await tester.pump(const Duration(seconds: 1));
    kolektakuRouter.go(Routes.search);
    await tester.pump(const Duration(seconds: 1));
    await tester.enterText(find.byType(EditableText), 'kimi no nawa');
    final found = await waitFor(
      tester,
      () => find.text('Kimi no Na wa.').evaluate().isNotEmpty,
      timeout: const Duration(seconds: 60),
    );
    expect(found, isTrue, reason: 'the film was not in the results');
  }, timeout: const Timeout(Duration(minutes: 3)));
}
