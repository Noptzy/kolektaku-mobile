import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/widgets/swipe_sheet.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/screen_harness.dart';

const _title = 'Judul sheet';

class Picked {
  String? value;
}

Future<Picked> open(WidgetTester tester) async {
  final picked = Picked();
  await ScreenHarness().pump(
    tester,
    Builder(
      builder: (context) => Center(
        child: ShadButton(
          key: const Key('open'),
          onPressed: () async {
            picked.value = await showSwipeSheet<String>(
              context: context,
              builder: (sheetContext) => ShadSheet(
                title: const Text(_title),
                child: ShadButton(
                  key: const Key('pick'),
                  onPressed: () => Navigator.of(sheetContext).pop('dipilih'),
                  child: const Text('Pilih'),
                ),
              ),
            );
          },
          child: const Text('Buka'),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const Key('open')));
  await tester.pumpAndSettle();
  return picked;
}

void main() {
  group('shouldDismiss', () {
    test('a long enough drag closes the sheet', () {
      expect(
        shouldDismiss(distance: sheetDismissDistance, velocity: 0),
        isTrue,
      );
      expect(
        shouldDismiss(distance: sheetDismissDistance - 1, velocity: 0),
        isFalse,
      );
    });

    test('a fast downward flick closes it even after a short drag', () {
      expect(
        shouldDismiss(distance: 10, velocity: sheetDismissVelocity),
        isTrue,
      );
      expect(shouldDismiss(distance: 10, velocity: 100), isFalse);
    });

    test('an upward flick never closes it', () {
      expect(shouldDismiss(distance: 0, velocity: -2000), isFalse);
    });
  });

  group('showSwipeSheet', () {
    testWidgets('shows the sheet with a grabber', (tester) async {
      await open(tester);
      expect(find.text(_title), findsOneWidget);
      expect(find.byKey(const Key('sheet-grabber')), findsOneWidget);
    });

    testWidgets('dragging down past the distance closes it', (tester) async {
      await open(tester);
      await tester.drag(find.text(_title), const Offset(0, 300));
      await tester.pumpAndSettle();
      expect(find.text(_title), findsNothing);
    });

    testWidgets('a short drag springs back and keeps it open', (tester) async {
      await open(tester);
      final before = tester.getTopLeft(find.text(_title));
      final gesture = await tester.startGesture(
        tester.getCenter(find.text(_title)),
      );
      await gesture.moveBy(const Offset(0, 40));
      await tester.pump();
      expect(tester.getTopLeft(find.text(_title)).dy, greaterThan(before.dy));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text(_title), findsOneWidget);
      expect(tester.getTopLeft(find.text(_title)), before);
    });

    testWidgets('a quick downward flick closes it', (tester) async {
      await open(tester);
      await tester.fling(find.text(_title), const Offset(0, 60), 2500);
      await tester.pumpAndSettle();
      expect(find.text(_title), findsNothing);
    });

    testWidgets('dragging up moves nothing', (tester) async {
      await open(tester);
      final before = tester.getTopLeft(find.text(_title));
      await tester.drag(find.text(_title), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(find.text(_title), findsOneWidget);
      expect(tester.getTopLeft(find.text(_title)), before);
    });

    testWidgets('choosing inside the sheet still returns its value', (
      tester,
    ) async {
      final picked = await open(tester);
      await tester.tap(find.byKey(const Key('pick')));
      await tester.pumpAndSettle();
      expect(picked.value, 'dipilih');
      expect(find.text(_title), findsNothing);
    });

    testWidgets('closing by swiping returns nothing', (tester) async {
      final picked = await open(tester);
      await tester.drag(find.text(_title), const Offset(0, 300));
      await tester.pumpAndSettle();
      expect(picked.value, isNull);
    });
  });
}
