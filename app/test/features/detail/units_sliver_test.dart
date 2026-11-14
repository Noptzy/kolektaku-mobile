import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/detail/units_sliver.dart';
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:kolektaku/src/rust/error.dart';
import 'package:kolektaku/src/rust/dto/sources.dart';

import '../../support/screen_harness.dart';
import 'detail_support.dart';

Future<void> show(
  WidgetTester tester,
  AsyncValue<UnitsDto> units,
  MediaKindDto kind,
) {
  return ScreenHarness().pump(
    tester,
    CustomScrollView(
      slivers: [
        UnitsSliver(
          units: units,
          view: catalogView(),
          kind: kind,
          progress: const {},
          descending: false,
          focus: null,
          onToggleOrder: () {},
          onRetry: () {},
          onPlay: (_) {},
        ),
      ],
    ),
    settle: false,
  );
}

AsyncValue<UnitsDto> failing(BridgeErrorKind kind) =>
    AsyncError(BridgeError(kind: kind, detail: 'x'), StackTrace.empty);

void main() {
  group('missing units', () {
    test('the title names episodes for anime and chapters for comics', () {
      expect(missingUnitsTitle(MediaKindDto.anime), 'Episode tidak ditemukan');
      expect(missingUnitsTitle(MediaKindDto.manga), 'Chapter tidak ditemukan');
    });

    testWidgets('a comic nobody has says its chapters were not found', (
      tester,
    ) async {
      await show(tester, failing(BridgeErrorKind.notFound), MediaKindDto.manga);
      expect(find.byKey(const Key('units-missing')), findsOneWidget);
      expect(find.text('Chapter tidak ditemukan'), findsOneWidget);
      expect(find.text('Ada yang tidak beres'), findsNothing);
    });

    testWidgets('an anime nobody has says its episodes were not found', (
      tester,
    ) async {
      await show(tester, failing(BridgeErrorKind.notFound), MediaKindDto.anime);
      expect(find.text('Episode tidak ditemukan'), findsOneWidget);
    });

    testWidgets('other failures still use the general error view', (
      tester,
    ) async {
      await show(
        tester,
        failing(BridgeErrorKind.unavailable),
        MediaKindDto.manga,
      );
      expect(find.byKey(const Key('units-missing')), findsNothing);
      expect(find.text('Ada yang tidak beres'), findsOneWidget);
    });

    testWidgets('an unknown failure offers a retry', (tester) async {
      await show(
        tester,
        AsyncError(StateError('boom'), StackTrace.empty),
        MediaKindDto.manga,
      );
      expect(find.text('Daftar belum bisa dimuat.'), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
    });
  });
}
