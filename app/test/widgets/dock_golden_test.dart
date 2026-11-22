import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/theme/glass_tokens.dart';
import 'package:kolektaku/widgets/app_shell.dart';
import 'package:kolektaku/core/theme/kolektaku_tokens.dart';
import 'package:kolektaku/widgets/floating_dock.dart';
import 'package:kolektaku/widgets/swipe_toast.dart';

import 'widget_harness.dart';

const _sizes = {'390x844': phoneLarge, '360x780': phoneSmall};
const _shot = Key('dock-shot');

Widget _posters() {
  return Column(
    children: [
      for (var row = 0; row < 8; row++)
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var col = 0; col < 3; col++)
                Expanded(
                  child: ColoredBox(
                    color: HSLColor.fromAHSL(
                      1,
                      ((row * 3 + col) * 47) % 360.0,
                      0.7,
                      0.42,
                    ).toColor(),
                  ),
                ),
            ],
          ),
        ),
    ],
  );
}

Widget _scene(int index) {
  return RepaintBoundary(
    key: _shot,
    child: Stack(
      children: [
        Positioned.fill(child: _posters()),
        Positioned(
          left: DockMetrics.sideInset,
          right: DockMetrics.sideInset,
          bottom: DockMetrics.bottomOffset(0),
          child: FloatingDock(
            destinations: appDestinations,
            currentIndex: index,
            onSelected: (_) {},
          ),
        ),
      ],
    ),
  );
}

Widget _sceneWithToast() {
  return RepaintBoundary(
    key: _shot,
    child: Stack(
      children: [
        Positioned.fill(child: _posters()),
        Positioned(
          left: Spacing.screenGutter,
          right: Spacing.screenGutter,
          bottom: DockMetrics.bottomOffset(0) + DockMetrics.height + Spacing.md,
          child: SwipeToast(
            message: 'Dihapus dari riwayat.',
            actionLabel: 'Urungkan',
            onAction: () {},
            onClosed: () {},
            duration: const Duration(minutes: 5),
          ),
        ),
        Positioned(
          left: DockMetrics.sideInset,
          right: DockMetrics.sideInset,
          bottom: DockMetrics.bottomOffset(0),
          child: FloatingDock(
            destinations: appDestinations,
            currentIndex: 2,
            onSelected: (_) {},
          ),
        ),
      ],
    ),
  );
}

void main() {
  _sizes.forEach((label, size) {
    testWidgets('dock over bright content at $label', (tester) async {
      await pumpAtSize(tester, _scene(1), size: size);
      await expectLater(
        find.byKey(_shot),
        matchesGoldenFile('goldens/dock_$label.png'),
      );
    });
  });

  _sizes.forEach((label, size) {
    testWidgets('toast above the dock at $label', (tester) async {
      await pumpAtSize(tester, _sceneWithToast(), size: size);
      await tester.pump(const Duration(milliseconds: 400));
      await expectLater(
        find.byKey(_shot),
        matchesGoldenFile('goldens/toast_$label.png'),
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
