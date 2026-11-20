import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'collection_support.dart';

void main() {
  testWidgets('typing in the search keeps only the matching titles', (
    tester,
  ) async {
    await open(
      tester,
      history: [
        progress(1, title: 'Hotaru no Yomeiri'),
        progress(2, title: 'Kusuriya no Hitorigoto'),
      ],
    );
    expect(find.text('Cari riwayat tontonan…'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('history-search')), 'hotaru');
    await tester.pumpAndSettle();
    expect(find.text('Hotaru no Yomeiri'), findsOneWidget);
    expect(find.text('Kusuriya no Hitorigoto'), findsNothing);
  });

  testWidgets('a search with no match says so', (tester) async {
    await open(tester, history: [progress(1, title: 'Hotaru no Yomeiri')]);
    await tester.enterText(find.byKey(const Key('history-search')), 'naruto');
    await tester.pumpAndSettle();
    expect(
      find.text('Tidak ada riwayat yang cocok dengan "naruto".'),
      findsOneWidget,
    );
  });

  testWidgets('a short history is only as tall as its rows', (tester) async {
    await open(tester, history: [progress(1), progress(2)]);
    final box = tester.getSize(find.byKey(const Key('history-list')));
    expect(box.height, lessThan(3 * 80));
  });
}
