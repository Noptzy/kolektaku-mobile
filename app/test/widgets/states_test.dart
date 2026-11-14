import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/widgets/media_card_skeleton.dart';
import 'package:kolektaku/widgets/skeleton.dart';
import 'package:kolektaku/widgets/state_view.dart';

import 'widget_harness.dart';

void main() {
  group('StateView', () {
    testWidgets('empty shows a title and message without an action', (
      tester,
    ) async {
      await pumpAtSize(
        tester,
        StateView.empty(title: 'Belum ada hasil', message: 'Coba kata lain.'),
      );
      expect(find.text('Belum ada hasil'), findsOneWidget);
      expect(find.text('Coba kata lain.'), findsOneWidget);
      expect(find.text('Coba lagi'), findsNothing);
    });

    testWidgets('error offers the action and reports taps', (tester) async {
      var taps = 0;
      await pumpAtSize(
        tester,
        StateView.error(
          title: 'Gagal memuat',
          actionLabel: 'Coba lagi',
          onAction: () => taps++,
        ),
      );
      await tester.tap(find.text('Coba lagi'));
      expect(taps, 1);
    });

    testWidgets('offline has Indonesian defaults', (tester) async {
      await pumpAtSize(tester, StateView.offline(onAction: () {}));
      expect(find.text('Tidak ada koneksi'), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
    });

    testWidgets('no action without a callback', (tester) async {
      await pumpAtSize(tester, const StateView.offline());
      expect(find.text('Coba lagi'), findsNothing);
    });
  });

  group('Skeleton', () {
    testWidgets('pulses while animations are allowed', (tester) async {
      await pumpAtSize(tester, const MediaCardSkeleton());
      expect(tester.hasRunningAnimations, isTrue);
    });

    testWidgets('a still skeleton schedules no frames', (tester) async {
      await pumpAtSize(tester, const MediaCardSkeleton(animate: false));
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('reduced motion keeps it still', (tester) async {
      await pumpAtSize(
        tester,
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Skeleton(width: 40, height: 10),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}
