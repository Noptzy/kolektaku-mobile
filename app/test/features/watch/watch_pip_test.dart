import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'watch_harness.dart';

void main() {
  testWidgets('the screen arms picture in picture while playing', (
    tester,
  ) async {
    final harness = WatchHarness();
    await harness.open(tester);
    expect(harness.pip.log, ['arm true']);
  });

  testWidgets('pausing and resuming updates the picture in picture button', (
    tester,
  ) async {
    final harness = WatchHarness();
    await harness.open(tester);
    await tester.tap(find.byKey(const Key('play-pause')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('play-pause')));
    await tester.pump();
    expect(harness.pip.log, ['arm true', 'update false', 'update true']);
  });

  testWidgets('the picture in picture button toggles playback', (tester) async {
    final harness = WatchHarness();
    await harness.open(tester);
    harness.pip.toggles.add(null);
    await tester.pump();
    harness.pip.toggles.add(null);
    await tester.pump();
    expect(harness.engine.log, containsAllInOrder(['pause', 'play']));
  });

  testWidgets('inside the small window only the video is shown', (
    tester,
  ) async {
    final harness = WatchHarness();
    await harness.open(tester);
    expect(find.byKey(const Key('play-pause')), findsOneWidget);
    harness.pip.modes.add(true);
    await tester.pump();
    expect(find.byKey(const Key('fake-video')), findsOneWidget);
    expect(find.byKey(const Key('play-pause')), findsNothing);
    expect(find.byKey(const Key('zone-forward')), findsNothing);
    expect(find.byKey(const Key('change-server')), findsNothing);
    harness.pip.modes.add(false);
    await tester.pump();
    expect(find.byKey(const Key('play-pause')), findsOneWidget);
    expect(find.byKey(const Key('change-server')), findsOneWidget);
  });

  testWidgets('leaving the screen disarms picture in picture', (tester) async {
    final harness = WatchHarness();
    await harness.open(tester);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(harness.pip.log.last, 'disarm');
  });

  testWidgets('a screen that failed to load never arms picture in picture', (
    tester,
  ) async {
    final harness = WatchHarness(failToLoad: true);
    await harness.open(tester);
    expect(harness.pip.log, isEmpty);
  });
}
