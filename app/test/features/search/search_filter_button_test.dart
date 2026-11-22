import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/search/search_filter_button.dart';

import '../../widgets/widget_harness.dart';

Widget _button(int count, VoidCallback onTap) => Align(
  alignment: Alignment.topLeft,
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: SearchFilterButton(count: count, onTap: onTap),
  ),
);

void main() {
  test('the label says how many filters are on', () {
    expect(filterButtonLabel(0), 'Filter');
    expect(filterButtonLabel(2), 'Filter (2)');
  });

  testWidgets('is a 48 dp square with no badge when nothing is filtered', (
    tester,
  ) async {
    await pumpAtSize(tester, _button(0, () {}));
    final size = tester.getSize(find.byType(SearchFilterButton));
    expect(size, const Size(48, 48));
    expect(find.byKey(const Key('filter-badge')), findsNothing);
  });

  testWidgets('shows the count of active filters as a badge', (tester) async {
    await pumpAtSize(tester, _button(2, () {}));
    expect(find.byKey(const Key('filter-badge')), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.bySemanticsLabel('Filter (2)'), findsOneWidget);
  });

  testWidgets('tapping opens the filters', (tester) async {
    var taps = 0;
    await pumpAtSize(tester, _button(0, () => taps++));
    await tester.tap(find.byType(SearchFilterButton));
    expect(taps, 1);
  });

  testWidgets('the badge does not change the size of the touch target', (
    tester,
  ) async {
    await pumpAtSize(tester, _button(3, () {}));
    expect(tester.getSize(find.byType(SearchFilterButton)), const Size(48, 48));
  });
}
