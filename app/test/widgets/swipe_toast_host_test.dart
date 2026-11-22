import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/theme/glass_tokens.dart';
import 'package:kolektaku/data/providers/download_providers.dart';
import 'package:kolektaku/data/providers/toast_providers.dart';
import 'package:kolektaku/widgets/swipe_toast_host.dart';

import '../support/fake_download_gateway.dart';
import 'widget_harness.dart';

Future<ProviderContainer> _show(
  WidgetTester tester, {
  Listenable? dismissOn,
}) async {
  final container = ProviderContainer(
    overrides: [
      downloadGatewayProvider.overrideWithValue(FakeDownloadGateway()),
    ],
  );
  addTearDown(container.dispose);
  await pumpAtSize(
    tester,
    UncontrolledProviderScope(
      container: container,
      child: SwipeToastHost(
        dismissOn: dismissOn,
        child: const SizedBox.expand(),
      ),
    ),
  );
  return container;
}

void _offer(ProviderContainer container, Future<void> Function() undo) {
  container
      .read(swipeToastProvider.notifier)
      .show(
        message: 'Dihapus dari riwayat.',
        actionLabel: 'Urungkan',
        onAction: undo,
      );
}

void main() {
  testWidgets('shows nothing until a toast is offered', (tester) async {
    await _show(tester);
    expect(find.text('Dihapus dari riwayat.'), findsNothing);
  });

  testWidgets('a toast floats above the dock, clear of its top edge', (
    tester,
  ) async {
    final container = await _show(tester);
    _offer(container, () async {});
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final toast = tester.getRect(find.text('Dihapus dari riwayat.'));
    final dockTop =
        phoneLarge.height - DockMetrics.bottomOffset(0) - DockMetrics.height;
    expect(toast.bottom, lessThanOrEqualTo(dockTop));
  });

  testWidgets('the action runs the undo and clears the toast', (tester) async {
    final container = await _show(tester);
    var undone = 0;
    _offer(container, () async => undone++);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Urungkan'));
    await tester.pump();
    expect(undone, 1);
    expect(container.read(swipeToastProvider), isNull);
  });

  testWidgets('a newer toast replaces the older one', (tester) async {
    final container = await _show(tester);
    _offer(container, () async {});
    container
        .read(swipeToastProvider.notifier)
        .show(
          message: 'Dihapus dari favorit.',
          actionLabel: 'Urungkan',
          onAction: () async {},
        );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Dihapus dari favorit.'), findsOneWidget);
    expect(find.text('Dihapus dari riwayat.'), findsNothing);
  });

  testWidgets('navigating away closes it', (tester) async {
    final navigation = ValueNotifier<int>(0);
    addTearDown(navigation.dispose);
    final container = await _show(tester, dismissOn: navigation);
    _offer(container, () async {});
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Dihapus dari riwayat.'), findsOneWidget);
    navigation.value = 1;
    await tester.pump();
    await tester.pump();
    expect(container.read(swipeToastProvider), isNull);
  });

  test('dismissing an old id leaves a newer toast alone', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(swipeToastProvider.notifier);
    controller.show(message: 'a', actionLabel: 'x', onAction: () async {});
    final first = container.read(swipeToastProvider)!.id;
    controller.show(message: 'b', actionLabel: 'x', onAction: () async {});
    controller.dismiss(first);
    expect(container.read(swipeToastProvider)?.message, 'b');
    controller.dismiss();
    expect(container.read(swipeToastProvider), isNull);
  });
}
