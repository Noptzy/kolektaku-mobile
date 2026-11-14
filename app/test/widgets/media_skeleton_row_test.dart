import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/watch/player/stream_spinner.dart';
import 'package:kolektaku/widgets/infinite_footer.dart';
import 'package:kolektaku/widgets/media_card_skeleton.dart';
import 'package:kolektaku/widgets/media_skeleton_row.dart';

import '../support/screen_harness.dart';

Future<void> show(WidgetTester tester, Widget child) {
  return ScreenHarness().pump(
    tester,
    Align(alignment: Alignment.topCenter, child: child),
    settle: false,
  );
}

void main() {
  group('MediaSkeletonRow', () {
    testWidgets('lays three card skeletons side by side with equal width', (
      tester,
    ) async {
      await show(tester, const MediaSkeletonRow(animate: false));
      final cards = find.byType(MediaCardSkeleton);
      expect(cards, findsNWidgets(3));
      final widths = [
        for (final element in cards.evaluate()) element.size!.width,
      ];
      expect(widths.toSet(), hasLength(1));
      expect(widths.first, greaterThan(80));
    });

    testWidgets('honours a custom column count', (tester) async {
      await show(tester, const MediaSkeletonRow(columns: 2, animate: false));
      expect(find.byType(MediaCardSkeleton), findsNWidgets(2));
    });
  });

  group('InfiniteFooter', () {
    testWidgets('shows card skeletons instead of a spinner while loading', (
      tester,
    ) async {
      await show(
        tester,
        InfiniteFooter(hasMore: true, loading: true, onMore: () {}),
      );
      expect(find.byKey(const Key('footer-skeleton')), findsOneWidget);
      expect(find.byType(StreamSpinner), findsNothing);
    });

    testWidgets('shows nothing extra when idle and finished', (tester) async {
      await show(
        tester,
        InfiniteFooter(hasMore: false, loading: false, onMore: () {}),
      );
      expect(find.byKey(const Key('footer-skeleton')), findsNothing);
    });
  });
}
