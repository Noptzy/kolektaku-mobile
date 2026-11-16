import 'package:flutter/material.dart' show Material;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/novel_reader/highlight_ranges.dart';
import 'package:kolektaku/features/novel_reader/marked_paragraph.dart';

import '../../support/screen_harness.dart';

const _text = 'Join the Classics Club today';

Future<void> show(
  WidgetTester tester, {
  List<Marked> marks = const [],
  HighlightPicked? onHighlight,
  ValueChanged<int>? onTapMark,
}) {
  return ScreenHarness().pump(
    tester,
    Material(
      child: Center(
        child: MarkedParagraph(
          text: _text,
          style: const TextStyle(fontSize: 10),
          marks: marks,
          onHighlight: onHighlight,
          onTapMark: onTapMark,
        ),
      ),
    ),
  );
}

List<InlineSpan> spansOf(WidgetTester tester) {
  final text = tester.widget<Text>(find.byKey(const Key('marked-paragraph')));
  final root = text.textSpan! as TextSpan;
  return root.children ?? const [];
}

void main() {
  testWidgets('a paragraph without marks stays plain readable text', (
    tester,
  ) async {
    await show(tester);
    expect(find.text(_text), findsOneWidget);
  });

  testWidgets('a mark paints a background behind exactly its words', (
    tester,
  ) async {
    await show(tester, marks: [(id: 5, start: 9, end: 22)]);
    final spans = spansOf(tester).cast<TextSpan>();
    expect(spans.map((span) => span.text), [
      'Join the ',
      'Classics Club',
      ' today',
    ]);
    expect(spans[0].style?.backgroundColor, isNull);
    expect(spans[1].style?.backgroundColor, isNotNull);
  });

  testWidgets('tapping a marked word reports which highlight it was', (
    tester,
  ) async {
    final tapped = <int>[];
    await show(
      tester,
      marks: [(id: 5, start: 0, end: _text.length)],
      onTapMark: tapped.add,
    );
    await tester.tap(find.byKey(const Key('marked-paragraph')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tapped, [5]);
  });

  testWidgets('selecting words offers to highlight them', (tester) async {
    final picked = <String>[];
    await show(
      tester,
      onHighlight: (start, end, quote) => picked.add('$start-$end-$quote'),
    );
    await tester.longPress(find.byKey(const Key('marked-paragraph')));
    await tester.pumpAndSettle();
    expect(find.text('Sorot'), findsOneWidget);
    await tester.tap(find.text('Sorot'));
    await tester.pumpAndSettle();
    expect(picked, hasLength(1));
    final parts = picked.single.split('-');
    final start = int.parse(parts[0]);
    final end = int.parse(parts[1]);
    expect(_text.substring(start, end), parts.sublist(2).join('-'));
  });

  testWidgets('without a handler the selection menu has no highlight', (
    tester,
  ) async {
    await show(tester);
    await tester.longPress(find.byKey(const Key('marked-paragraph')));
    await tester.pumpAndSettle();
    expect(find.text('Sorot'), findsNothing);
  });
}
