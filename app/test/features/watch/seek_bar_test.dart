import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/watch/player/playback_engine.dart';
import 'package:kolektaku/features/watch/player/seek_bar.dart';
import 'package:kolektaku/features/watch/player/seek_painter.dart';
import 'package:kolektaku/features/watch/player/skip_logic.dart';
import 'package:kolektaku/src/rust/dto/stream_extras.dart';

import '../../support/screen_harness.dart';

SkipDto skip(String kind, int start, int end) =>
    SkipDto(kind: kind, startMs: BigInt.from(start), endMs: BigInt.from(end));

const length = Duration(minutes: 20);

Future<(List<double>, ValueNotifier<List<SkipDto>>)> show(
  WidgetTester tester, {
  List<SkipDto> skips = const [],
  Duration position = Duration.zero,
}) async {
  final seeks = <double>[];
  final marks = ValueNotifier<List<SkipDto>>(skips);
  addTearDown(marks.dispose);
  final snapshot = ValueNotifier(
    PlaybackSnapshot(position: position, duration: length),
  );
  addTearDown(snapshot.dispose);
  await ScreenHarness().pump(
    tester,
    Center(
      child: SizedBox(
        width: 300,
        child: SeekBar(snapshot: snapshot, onSeek: seeks.add, skips: marks),
      ),
    ),
  );
  return (seeks, marks);
}

SeekPainter painter(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find.descendant(
      of: find.byKey(const Key('seek-bar')),
      matching: find.byType(CustomPaint),
    ),
  );
  return paint.painter! as SeekPainter;
}

void main() {
  group('skipFractions', () {
    test('turns times into positions on the bar', () {
      final spans = skipFractions([
        skip('intro', 60000, 120000),
        skip('outro', 1080000, 1200000),
      ], length);
      expect(spans[0].$1, closeTo(0.05, 1e-9));
      expect(spans[0].$2, closeTo(0.1, 1e-9));
      expect(spans[1].$1, closeTo(0.9, 1e-9));
      expect(spans[1].$2, closeTo(1, 1e-9));
    });

    test('ignores an unknown length and empty or reversed ranges', () {
      expect(skipFractions([skip('intro', 0, 1000)], Duration.zero), isEmpty);
      expect(
        skipFractions([
          skip('intro', 5000, 5000),
          skip('intro', 9000, 4000),
        ], length),
        isEmpty,
      );
    });

    test('keeps a range that runs past the end inside the bar', () {
      final spans = skipFractions([skip('outro', 1100000, 9999999)], length);
      expect(spans.single.$2, 1);
    });
  });

  group('SeekBar', () {
    testWidgets('paints the intro and outro in their own colour', (
      tester,
    ) async {
      await show(
        tester,
        skips: [skip('intro', 60000, 120000), skip('outro', 1080000, 1190000)],
      );
      expect(painter(tester).marks, hasLength(2));
      expect(painter(tester).markColor, skipMarkColor);
      expect(painter(tester).markColor, isNot(painter(tester).playedColor));
    });

    testWidgets('has no marks when the episode has none', (tester) async {
      await show(tester);
      expect(painter(tester).marks, isEmpty);
    });

    testWidgets('marks appear when the stream brings them', (tester) async {
      final (_, marks) = await show(tester);
      marks.value = [skip('intro', 0, 90000)];
      await tester.pump();
      expect(painter(tester).marks, hasLength(1));
    });

    testWidgets('follows the playback position', (tester) async {
      await show(tester, position: const Duration(minutes: 10));
      expect(painter(tester).fraction, closeTo(0.5, 1e-9));
    });

    testWidgets('a tap seeks to that place', (tester) async {
      final (seeks, _) = await show(tester);
      final box = tester.getRect(find.byKey(const Key('seek-bar')));
      await tester.tapAt(Offset(box.left + seekInset + 140, box.center.dy));
      expect(seeks.single, closeTo(0.5, 0.01));
    });

    testWidgets('a drag seeks once when the finger lifts', (tester) async {
      final (seeks, _) = await show(tester);
      final box = tester.getRect(find.byKey(const Key('seek-bar')));
      final gesture = await tester.startGesture(
        Offset(box.left + seekInset, box.center.dy),
      );
      await gesture.moveBy(const Offset(100, 0));
      await tester.pump();
      expect(seeks, isEmpty);
      expect(painter(tester).dragging, isTrue);
      await gesture.moveBy(const Offset(100, 0));
      await gesture.up();
      await tester.pump();
      expect(seeks, hasLength(1));
      expect(seeks.single, closeTo(0.71, 0.05));
      expect(painter(tester).dragging, isFalse);
    });

    testWidgets('dragging past the ends stays inside the video', (
      tester,
    ) async {
      final (seeks, _) = await show(tester);
      final box = tester.getRect(find.byKey(const Key('seek-bar')));
      final gesture = await tester.startGesture(
        Offset(box.left + seekInset + 50, box.center.dy),
      );
      await gesture.moveBy(const Offset(-500, 0));
      await gesture.up();
      await tester.pump();
      expect(seeks.single, 0);
    });
  });
}
