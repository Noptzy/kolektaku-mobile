import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/widgets/pop_icon.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'widget_harness.dart';

Widget _icon({required bool selected, bool spin = false}) => PopIcon(
  icon: LucideIcons.house,
  color: const Color(0xFFFFFFFF),
  selected: selected,
  spin: spin,
);

double _scale(WidgetTester tester) {
  final transforms = tester.widgetList<Transform>(
    find.descendant(of: find.byType(PopIcon), matching: find.byType(Transform)),
  );
  return transforms.first.transform.storage[0];
}

void main() {
  testWidgets('rests at normal size', (tester) async {
    await pumpAtSize(tester, _icon(selected: true));
    expect(_scale(tester), closeTo(1, 0.001));
  });

  testWidgets('pops when it becomes selected, then settles at normal size', (
    tester,
  ) async {
    await pumpAtSize(tester, _icon(selected: false));
    await pumpAtSize(tester, _icon(selected: true));
    await tester.pump(const Duration(milliseconds: 30));
    expect(_scale(tester), isNot(closeTo(1, 0.01)));
    await tester.pump(const Duration(milliseconds: 400));
    expect(_scale(tester), closeTo(1, 0.001));
  });

  testWidgets('stays still when animations are disabled', (tester) async {
    Widget wrap(bool selected) => MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: _icon(selected: selected),
    );
    await pumpAtSize(tester, wrap(false));
    await pumpAtSize(tester, wrap(true));
    await tester.pump(const Duration(milliseconds: 30));
    expect(_scale(tester), closeTo(1, 0.001));
  });

  testWidgets('a spinning icon ends facing the way it started', (tester) async {
    await pumpAtSize(tester, _icon(selected: false, spin: true));
    await pumpAtSize(tester, _icon(selected: true, spin: true));
    await tester.pump(const Duration(milliseconds: 600));
    final rotate = tester
        .widgetList<Transform>(
          find.descendant(
            of: find.byType(PopIcon),
            matching: find.byType(Transform),
          ),
        )
        .last;
    expect(rotate.transform.storage[1].abs(), lessThan(0.001));
  });

  testWidgets('selecting it again while already selected does nothing', (
    tester,
  ) async {
    await pumpAtSize(tester, _icon(selected: true));
    await pumpAtSize(tester, _icon(selected: true));
    await tester.pump(const Duration(milliseconds: 30));
    expect(_scale(tester), closeTo(1, 0.001));
  });
}
