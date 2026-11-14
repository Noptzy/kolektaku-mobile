import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kolektaku/app.dart';
import 'package:kolektaku/app_scope.dart';
import 'package:kolektaku/core/router.dart';
import 'package:kolektaku/core/routes.dart';
import 'package:kolektaku/data/core_session.dart';
import 'package:kolektaku/features/detail/detail_request.dart';
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:kolektaku/src/rust/frb_generated.dart';

import 'support/pipeline_steps.dart';
import 'support/watch_driver.dart';

const hold = int.fromEnvironment('HOLD', defaultValue: 0);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await RustLib.init();
    await startCore();
  });

  testWidgets('a real title shows its detail with a source and a button', (
    tester,
  ) async {
    await tester.pumpWidget(kolektakuScope(child: const KolektakuApp()));
    await tester.pump(const Duration(seconds: 1));
    kolektakuRouter.push(
      Routes.detail,
      extra: DetailRequest(
        kind: MediaKindDto.anime,
        reference: catalogRef(21519),
      ),
    );
    final loaded = await waitFor(
      tester,
      () => find.textContaining('Sumber:').evaluate().isNotEmpty,
      timeout: const Duration(seconds: 90),
    );
    expect(loaded, isTrue, reason: 'the detail never loaded');
    expect(find.text('Kimi no Na wa.'), findsWidgets);
    final ready = await waitFor(
      tester,
      () => find.text('Tonton film').evaluate().isNotEmpty,
      timeout: const Duration(seconds: 90),
    );
    expect(ready, isTrue, reason: 'the film button never became ready');
    if (hold > 0) await tester.pump(const Duration(seconds: hold));
  }, timeout: const Timeout(Duration(minutes: 5)));
}
