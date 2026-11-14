import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/watch/player/video_quality.dart';

import 'player_extras_ui_support.dart';

void main() {
  testWidgets('a stream without subtitles has no subtitle button', (
    tester,
  ) async {
    await show(tester);
    expect(find.byKey(const Key('subtitles')), findsNothing);
  });

  testWidgets('the skip button shows inside the intro and jumps to its end', (
    tester,
  ) async {
    final (engine, _) = await show(tester);
    expect(find.byKey(const Key('skip-button')), findsNothing);
    engine.emit(position: const Duration(seconds: 80), playing: true);
    await tester.pump();
    expect(find.text('Lewati intro'), findsOneWidget);
    await tester.tap(find.byKey(const Key('skip-button')));
    await tester.pump();
    expect(engine.log, contains('seek 158'));
    expect(find.byKey(const Key('skip-button')), findsNothing);
  });

  testWidgets('the skip button is usable even when the controls are hidden', (
    tester,
  ) async {
    final (engine, _) = await show(tester, controlsVisible: false);
    engine.emit(position: const Duration(seconds: 80), playing: true);
    await tester.pump();
    expect(find.byKey(const Key('skip-button')), findsOneWidget);
  });

  testWidgets('an adaptive stream offers a resolution menu with auto first', (
    tester,
  ) async {
    final (engine, session) = await show(
      tester,
      qualities: const [
        VideoQuality(id: 'a', height: 1080, label: '1080p'),
        VideoQuality(id: 'b', height: 720, label: '720p'),
      ],
    );
    expect(find.text('Otomatis'), findsOneWidget);
    await tester.tap(find.byKey(const Key('quality')));
    await tester.pumpAndSettle();
    expect(find.text('Otomatis  •'), findsOneWidget);
    await tester.tap(find.byKey(const Key('option-720p')));
    await tester.pumpAndSettle();
    expect(engine.selectedQualities, ['b']);
    expect(session.extras.trackId.value, 'b');
    expect(find.text('720p'), findsOneWidget);
  });

  testWidgets('a stream with a single resolution shows no resolution button', (
    tester,
  ) async {
    await show(tester);
    expect(find.byKey(const Key('quality')), findsNothing);
  });
}
