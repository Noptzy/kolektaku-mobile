import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/theme/kolektaku_tokens.dart';
import 'package:kolektaku/widgets/filter_sheet.dart';

import 'widget_harness.dart';

const _sizes = {'390x844': phoneLarge, '360x780': phoneSmall};
const _shot = Key('filter-shot');

const _sections = [
  FilterSection(
    key: 'format',
    title: 'Format',
    options: [
      FilterOption('all', 'Semua'),
      FilterOption('tv', 'TV'),
      FilterOption('movie', 'Film'),
      FilterOption('ova', 'OVA'),
    ],
  ),
  FilterSection(
    key: 'order',
    title: 'Urutan',
    options: [
      FilterOption('relevance', 'Relevan'),
      FilterOption('score', 'Skor tertinggi'),
      FilterOption('new', 'Terbaru'),
    ],
  ),
  FilterSection(
    key: 'genre',
    title: 'Genre',
    options: [
      FilterOption('all', 'Semua'),
      FilterOption('a', 'Aksi'),
      FilterOption('b', 'Petualangan'),
      FilterOption('c', 'Komedi'),
      FilterOption('d', 'Drama'),
      FilterOption('e', 'Fantasi'),
      FilterOption('f', 'Horor'),
    ],
  ),
];

void main() {
  _sizes.forEach((label, size) {
    testWidgets('filter sheet body at $label', (tester) async {
      await pumpAtSize(
        tester,
        Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: _shot,
            child: ColoredBox(
              color: const Color(0xFF17171D),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                child: FilterSheetBody(
                  sections: _sections,
                  current: const {
                    'format': 'tv',
                    'order': 'score',
                    'genre': 'c',
                  },
                  initial: const {
                    'format': 'all',
                    'order': 'relevance',
                    'genre': 'all',
                  },
                  onApply: (_) {},
                ),
              ),
            ),
          ),
        ),
        size: size,
      );
      await expectLater(
        find.byKey(_shot),
        matchesGoldenFile('goldens/filter_sheet_$label.png'),
      );
    });
  });
}
