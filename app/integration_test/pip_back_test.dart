import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kolektaku/core/router.dart';
import 'package:kolektaku/data/core_session.dart';
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:kolektaku/src/rust/frb_generated.dart';

import 'support/open_watch.dart';
import 'support/pipeline_steps.dart';
import 'support/watch_driver.dart';

const kimiNoNaWa = 21519;

void mark(String name) => debugPrint('MARK $name');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await RustLib.init();
    await startCore();
    await openDetail(MediaKindDto.anime, catalogRef(kimiNoNaWa));
  });

  testWidgets('back leaves the player and never opens the small window', (
    tester,
  ) async {
    await openWatch(tester, catalogId: kimiNoNaWa, title: 'Kimi no Na wa.');
    mark('READY_FOR_BACK');
    final left = await waitFor(
      tester,
      () => find.byKey(const Key('episode-label')).evaluate().isEmpty,
      timeout: const Duration(seconds: 120),
    );
    expect(left, isTrue, reason: 'back did not close the player');
    expect(kolektakuRouter.canPop(), isFalse);
    mark('BACK_DONE');
    await pumpFor(tester, const Duration(seconds: 6));
    mark('SETTLED');
    await waitUntilReleased(tester: tester);
  }, timeout: const Timeout(Duration(minutes: 6)));
}
