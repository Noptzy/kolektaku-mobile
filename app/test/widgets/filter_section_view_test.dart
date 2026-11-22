import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/widgets/filter_section_view.dart';
import 'package:kolektaku/widgets/filter_sheet.dart';
import 'package:kolektaku/widgets/option_chip.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'widget_harness.dart';

FilterSection _section(int count, {String key = 'order'}) => FilterSection(
  key: key,
  title: 'Urutan',
  options: [for (var i = 0; i < count; i++) FilterOption('o$i', 'Opsi $i')],
);

Widget _view(
  FilterSection section, {
  String? selected,
  ValueChanged<String>? onPick,
}) {
  return Align(
    alignment: Alignment.topLeft,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: FilterSectionView(
        section: section,
        selected: selected,
        onPick: onPick ?? (_) {},
      ),
    ),
  );
}

double _checkOpacity(WidgetTester tester, String optionKey) {
  final row = find.byKey(Key(optionKey));
  final opacity = find.descendant(
    of: row,
    matching: find.byType(AnimatedOpacity),
  );
  return tester.widget<AnimatedOpacity>(opacity).opacity;
}

void main() {
  testWidgets('a short section is a grouped list, not chips', (tester) async {
    await pumpAtSize(tester, _view(_section(4), selected: 'o1'));
    expect(find.byType(OptionChip), findsNothing);
    for (var i = 0; i < 4; i++) {
      expect(find.byKey(Key('order-o$i')), findsOneWidget);
    }
  });

  testWidgets('exactly six options is still a list, seven becomes chips', (
    tester,
  ) async {
    await pumpAtSize(tester, _view(_section(filterListMaxOptions)));
    expect(find.byType(OptionChip), findsNothing);
    await pumpAtSize(tester, _view(_section(filterListMaxOptions + 1)));
    expect(find.byType(OptionChip), findsNWidgets(filterListMaxOptions + 1));
  });

  testWidgets('only the chosen row shows its check', (tester) async {
    await pumpAtSize(tester, _view(_section(3), selected: 'o1'));
    expect(_checkOpacity(tester, 'order-o0'), 0);
    expect(_checkOpacity(tester, 'order-o1'), 1);
    expect(_checkOpacity(tester, 'order-o2'), 0);
    expect(find.byIcon(LucideIcons.check), findsNWidgets(3));
  });

  testWidgets('tapping a row reports its id', (tester) async {
    final picked = <String>[];
    await pumpAtSize(tester, _view(_section(3), onPick: picked.add));
    await tester.tap(find.byKey(const Key('order-o2')));
    await tester.tap(find.text('Opsi 0'));
    expect(picked, ['o2', 'o0']);
  });

  testWidgets('chips keep their keys and selection for long sections', (
    tester,
  ) async {
    final picked = <String>[];
    await pumpAtSize(
      tester,
      _view(
        _section(9, key: 'genre'),
        selected: 'o4',
        onPick: picked.add,
      ),
    );
    await tester.tap(find.byKey(const Key('genre-o7')));
    expect(picked, ['o7']);
  });

  testWidgets('rows are 48 dp tall and announce selection', (tester) async {
    await pumpAtSize(tester, _view(_section(3), selected: 'o1'));
    final target = find.ancestor(
      of: find.text('Opsi 1'),
      matching: find.byType(GestureDetector),
    );
    expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
    final node = tester.getSemantics(target);
    expect(node.hasFlag(SemanticsFlag.isSelected), isTrue);
    final other = tester.getSemantics(
      find.ancestor(
        of: find.text('Opsi 0'),
        matching: find.byType(GestureDetector),
      ),
    );
    expect(other.hasFlag(SemanticsFlag.isSelected), isFalse);
  });

  testWidgets('a very long option label ends in an ellipsis, not overflow', (
    tester,
  ) async {
    const long =
        'Judul pilihan yang panjang sekali sampai tidak muat di satu baris '
        'pada layar telepon kecil';
    await pumpAtSize(
      tester,
      _view(
        const FilterSection(
          key: 'order',
          title: 'Urutan',
          options: [FilterOption('a', long), FilterOption('b', 'Pendek')],
        ),
      ),
      size: phoneSmall,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the section title sits above the options', (tester) async {
    await pumpAtSize(tester, _view(_section(3)));
    final title = tester.getTopLeft(find.text('Urutan')).dy;
    final first = tester.getTopLeft(find.byKey(const Key('order-o0'))).dy;
    expect(first, greaterThan(title));
  });
}
