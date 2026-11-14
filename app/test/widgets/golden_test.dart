import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/theme/kolektaku_tokens.dart';
import 'package:kolektaku/features/dev/gallery/component_samples.dart';
import 'package:kolektaku/features/dev/gallery/gallery_section.dart';
import 'package:kolektaku/features/dev/gallery/sample_media.dart';
import 'package:kolektaku/widgets/media_rail.dart';
import 'package:kolektaku/widgets/state_view.dart';
import 'package:kolektaku/widgets/top10_rail.dart';

import 'widget_harness.dart';

const _sizes = {'390x844': phoneLarge, '360x780': phoneSmall};
const _shot = Key('shot');

Widget shot(Widget child) => Align(
  alignment: Alignment.topCenter,
  child: RepaintBoundary(key: _shot, child: child),
);

Future<void> check(
  WidgetTester tester,
  String name,
  String label,
  Size size,
  Widget child,
) async {
  await pumpAtSize(tester, shot(child), size: size);
  await expectLater(
    find.byKey(_shot),
    matchesGoldenFile('goldens/${name}_$label.png'),
  );
}

void main() {
  _sizes.forEach((label, size) {
    group('golden $label', () {
      testWidgets('hero', (tester) async {
        await check(tester, 'hero', label, size, const HeroSample());
      });

      testWidgets('rails', (tester) async {
        final cards = sampleCards(10);
        await check(
          tester,
          'rails',
          label,
          size,
          Column(
            spacing: Spacing.xl,
            children: [
              MediaRail(
                title: 'Lanjut nonton',
                cards: cards,
                progressOf: (card) => 0.15 * (cards.indexOf(card) % 6),
              ),
              Top10Rail(title: 'Top 10 hari ini', cards: cards),
            ],
          ),
        );
      });

      testWidgets('new episodes', (tester) async {
        await check(
          tester,
          'new',
          label,
          size,
          MediaRail(
            title: 'Episode baru',
            cards: sampleCards(6),
            newOnly: true,
          ),
        );
      });

      testWidgets('genres and skeletons', (tester) async {
        await check(
          tester,
          'genres',
          label,
          size,
          const Column(
            children: [
              GallerySection(
                title: 'Genre',
                titleInset: Spacing.screenGutter,
                child: GenreSamples(),
              ),
              GallerySection(
                title: 'Memuat',
                titleInset: Spacing.screenGutter,
                child: SkeletonSamples(),
              ),
            ],
          ),
        );
      });

      testWidgets('empty state', (tester) async {
        await check(
          tester,
          'state_empty',
          label,
          size,
          const StateView.empty(
            title: 'Belum ada hasil',
            message: 'Coba kata kunci lain.',
          ),
        );
      });

      testWidgets('error state', (tester) async {
        await check(
          tester,
          'state_error',
          label,
          size,
          StateView.error(
            title: 'Gagal memuat',
            message: 'Terjadi masalah saat mengambil data.',
            actionLabel: 'Coba lagi',
            onAction: () {},
          ),
        );
      });

      testWidgets('offline state', (tester) async {
        await check(
          tester,
          'state_offline',
          label,
          size,
          StateView.offline(onAction: () {}),
        );
      });
    });
  });
}
