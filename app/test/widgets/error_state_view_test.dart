import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/src/rust/error.dart';
import 'package:kolektaku/widgets/error_state_view.dart';

import 'widget_harness.dart';

BridgeError error(BridgeErrorKind kind) =>
    BridgeError(kind: kind, detail: 'teknis');

void main() {
  testWidgets('a network failure shows the offline state with retry', (
    tester,
  ) async {
    var retries = 0;
    await pumpAtSize(
      tester,
      ErrorStateView(
        error: error(BridgeErrorKind.network),
        onRetry: () => retries++,
      ),
    );
    expect(find.text('Tidak ada koneksi'), findsOneWidget);
    await tester.tap(find.text('Coba lagi'));
    expect(retries, 1);
  });

  testWidgets('an unreachable source shows its message and retry', (
    tester,
  ) async {
    await pumpAtSize(
      tester,
      ErrorStateView(error: error(BridgeErrorKind.unavailable), onRetry: () {}),
    );
    expect(find.text('Ada yang tidak beres'), findsOneWidget);
    expect(find.textContaining('tidak bisa dijangkau'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });

  testWidgets('a permanent failure offers no retry even with a callback', (
    tester,
  ) async {
    await pumpAtSize(
      tester,
      ErrorStateView(error: error(BridgeErrorKind.notFound), onRetry: () {}),
    );
    expect(find.textContaining('tidak ada di sumber ini'), findsOneWidget);
    expect(find.text('Coba lagi'), findsNothing);
  });

  testWidgets('technical detail is never shown', (tester) async {
    await pumpAtSize(
      tester,
      ErrorStateView(error: error(BridgeErrorKind.markupChanged)),
    );
    expect(find.textContaining('teknis'), findsNothing);
  });
}
