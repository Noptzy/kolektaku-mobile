import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/search/search_tab_screen.dart';
import 'package:kolektaku/features/watch/player/stream_spinner.dart';
import 'package:kolektaku/widgets/media_card_skeleton.dart';

import '../../support/screen_harness.dart';
import 'search_support.dart';

Future<void> typeAndWait(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(EditableText), text);
  await tester.pump(const Duration(milliseconds: 300));
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('the next page shows card skeletons, not a spinner', (
    tester,
  ) async {
    final harness = ScreenHarness()
      ..catalog.onSearch = (kind, query, number) {
        if (number == 1) {
          return Future.value(page([card(1, title: 'Satu')], hasNext: true));
        }
        return Completer<dynamic>().future.then((_) => page([]));
      };
    await harness.pump(tester, const SearchTabScreen(), settle: false);
    await typeAndWait(tester, 'a');
    expect(find.text('Satu'), findsOneWidget);
    expect(find.byKey(const Key('footer-skeleton')), findsOneWidget);
    expect(find.byType(MediaCardSkeleton), findsWidgets);
    expect(find.byType(StreamSpinner), findsNothing);
  });
}
