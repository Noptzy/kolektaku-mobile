import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/theme/glass_tokens.dart';
import 'package:kolektaku/widgets/dock_indicator.dart';
import 'package:kolektaku/widgets/floating_dock.dart';
import 'package:kolektaku/widgets/pop_icon.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'widget_harness.dart';

const _items = [
  BottomDestination(label: 'Satu', icon: LucideIcons.house),
  BottomDestination(label: 'Dua', icon: LucideIcons.search),
  BottomDestination(label: 'Tiga', icon: LucideIcons.bookmark),
  BottomDestination(label: 'Empat', icon: LucideIcons.settings, spin: true),
];

Widget _dock({int index = 0, ValueChanged<int>? onSelected}) {
  return Align(
    alignment: Alignment.bottomCenter,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: DockMetrics.sideInset),
      child: FloatingDock(
        destinations: _items,
        currentIndex: index,
        onSelected: onSelected ?? (_) {},
      ),
    ),
  );
}

void main() {
  testWidgets('shows every destination label', (tester) async {
    await pumpAtSize(tester, _dock());
    for (final label in ['Satu', 'Dua', 'Tiga', 'Empat']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('is 64 dp tall and pill shaped', (tester) async {
    await pumpAtSize(tester, _dock());
    expect(
      tester.getSize(find.byType(FloatingDock)).height,
      DockMetrics.height,
    );
  });

  testWidgets('tapping a destination reports its index', (tester) async {
    final picked = <int>[];
    await pumpAtSize(tester, _dock(onSelected: picked.add));
    await tester.tap(find.text('Tiga'));
    await tester.tap(find.text('Satu'));
    expect(picked, [2, 0]);
  });

  testWidgets(
    'every item is at least 48 dp and the selected one is announced',
    (tester) async {
      await pumpAtSize(tester, _dock(index: 1));
      for (final label in ['Satu', 'Dua', 'Tiga', 'Empat']) {
        final target = find.ancestor(
          of: find.text(label),
          matching: find.byType(GestureDetector),
        );
        final size = tester.getSize(target);
        expect(size.height, greaterThanOrEqualTo(48), reason: label);
        expect(size.width, greaterThanOrEqualTo(48), reason: label);
      }
      final selected = tester.getSemantics(
        find.ancestor(
          of: find.text('Dua'),
          matching: find.byType(GestureDetector),
        ),
      );
      expect(selected.hasFlag(SemanticsFlag.isSelected), isTrue);
      final other = tester.getSemantics(
        find.ancestor(
          of: find.text('Satu'),
          matching: find.byType(GestureDetector),
        ),
      );
      expect(other.hasFlag(SemanticsFlag.isSelected), isFalse);
    },
  );

  testWidgets('the indicator slides one slot per tab', (tester) async {
    await pumpAtSize(tester, _dock());
    Offset slide() => tester
        .widget<AnimatedSlide>(
          find.descendant(
            of: find.byType(DockIndicator),
            matching: find.byType(AnimatedSlide),
          ),
        )
        .offset;
    expect(slide(), Offset.zero);
    await pumpAtSize(tester, _dock(index: 3));
    expect(slide(), const Offset(3, 0));
  });

  testWidgets('the indicator sits behind the selected slot', (tester) async {
    await pumpAtSize(tester, _dock(index: 2));
    await tester.pumpAndSettle();
    final pill = tester.getRect(
      find.descendant(
        of: find.byType(DockIndicator),
        matching: find.byType(DecoratedBox),
      ),
    );
    final label = tester.getCenter(find.text('Tiga'));
    expect(pill.center.dx, closeTo(label.dx, 1));
    final dock = tester.getRect(find.byType(FloatingDock));
    expect(pill.left, greaterThanOrEqualTo(dock.left));
    expect(pill.right, lessThanOrEqualTo(dock.right));
    expect(pill.height, DockMetrics.height - 2 * DockMetrics.itemPadding);
  });

  testWidgets('the indicator does not animate when animations are off', (
    tester,
  ) async {
    await pumpAtSize(
      tester,
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: _dock(),
      ),
    );
    final slide = tester.widget<AnimatedSlide>(
      find.descendant(
        of: find.byType(DockIndicator),
        matching: find.byType(AnimatedSlide),
      ),
    );
    expect(slide.duration, Duration.zero);
  });

  testWidgets('only the settings icon spins', (tester) async {
    await pumpAtSize(tester, _dock());
    final icons = tester.widgetList<PopIcon>(find.byType(PopIcon)).toList();
    expect(icons.map((icon) => icon.spin), [false, false, false, true]);
  });
}
