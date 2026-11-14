import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/data/providers/settings_providers.dart';
import 'package:kolektaku/features/detail/detail_skeleton.dart';
import 'package:kolektaku/features/settings/subtitle_preview.dart';
import 'package:kolektaku/features/settings/swatch_row.dart';
import 'package:kolektaku/widgets/skeleton.dart';

import '../support/screen_harness.dart';

Future<void> show(WidgetTester tester, Widget child) {
  return ScreenHarness().pump(
    tester,
    ColoredBox(color: const Color(0xFF0E0E12), child: child),
    settle: false,
  );
}

void main() {
  group('Skeleton without a width', () {
    testWidgets('fills the line even inside a column that starts at the edge', (
      tester,
    ) async {
      await show(
        tester,
        const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Skeleton(key: Key('bar'), height: 14, animate: false)],
          ),
        ),
      );
      expect(tester.getSize(find.byKey(const Key('bar'))).width, 390 - 32);
    });

    testWidgets('keeps a width it was given', (tester) async {
      await show(
        tester,
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Skeleton(key: Key('bar'), width: 120, height: 14, animate: false),
          ],
        ),
      );
      expect(tester.getSize(find.byKey(const Key('bar'))).width, 120);
    });

    testWidgets('does not break inside a row with no width limit', (
      tester,
    ) async {
      await show(
        tester,
        const Row(children: [Skeleton(height: 10, animate: false)]),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('DetailSkeleton', () {
    testWidgets('draws the hero across the screen and bars you can see', (
      tester,
    ) async {
      await show(tester, const DetailSkeleton(animate: false));
      final blocks = tester.widgetList<Skeleton>(find.byType(Skeleton));
      expect(blocks.length, greaterThan(8));
      final hero = tester.getSize(find.byType(Skeleton).first);
      expect(hero.width, 390);
      expect(hero.height, greaterThan(150));
      for (final element in find.byType(Skeleton).evaluate()) {
        final size = element.size!;
        expect(size.width, greaterThan(0));
        expect(size.height, greaterThan(0));
      }
    });
  });

  group('SubtitlePreview', () {
    testWidgets('paints its light and dark halves at full height', (
      tester,
    ) async {
      await show(
        tester,
        Align(
          alignment: Alignment.topCenter,
          child: SubtitlePreview(settings: defaultSettings),
        ),
      );
      final inside = find.descendant(
        of: find.byType(SubtitlePreview),
        matching: find.byType(ColoredBox),
      );
      final halves = inside.evaluate().where((element) {
        final box = element.widget as ColoredBox;
        return box.color == const Color(0xFFE9E3D2) ||
            box.color == const Color(0xFF2B2B35);
      }).toList();
      expect(halves, hasLength(2));
      for (final element in halves) {
        expect(element.size!.height, 120);
        expect(element.size!.width, greaterThan(100));
      }
    });
  });

  group('SwatchRow', () {
    testWidgets('lines the colours up side by side', (tester) async {
      await show(
        tester,
        SwatchRow<int>(
          title: 'Warna',
          options: const [
            (1, Color(0xFFFFFFFF), 'Putih'),
            (2, Color(0xFFFFE04A), 'Kuning'),
            (3, Color(0xFF7CF29A), 'Hijau'),
            (4, Color(0xFF6FE3FF), 'Biru'),
            (5, Color(0xFFFF9EC8), 'Merah muda'),
          ],
          value: 1,
          onChanged: (_) {},
        ),
      );
      final dots = [
        for (var id = 1; id <= 5; id++)
          tester.getCenter(find.byKey(Key('swatch-$id'))),
      ];
      expect(dots.map((dot) => dot.dy).toSet(), hasLength(1));
      for (var i = 1; i < dots.length; i++) {
        expect(dots[i].dx, greaterThan(dots[i - 1].dx));
      }
    });
  });
}
