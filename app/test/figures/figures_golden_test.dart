import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/hairline/brush.dart';
import 'package:kolektaku/figures/gulungan.dart';
import 'package:kolektaku/figures/lupa.dart';
import 'package:kolektaku/figures/tumpuk.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../widgets/widget_harness.dart';

const _shot = Key('figure-shot');

class _Frame extends CustomPainter {
  _Frame(this.figure, this.palette, this.nowMs);

  final HairlineFigure figure;
  final HairlinePalette palette;
  final double nowMs;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / hairlineWidth;
    canvas.scale(scale);
    figure.paint(HairlineBrush(canvas, palette, scale), nowMs);
  }

  @override
  bool shouldRepaint(_Frame oldDelegate) => true;
}

Widget _sheet(List<(HairlineFigure, double)> frames) {
  return Builder(
    builder: (context) {
      final palette = HairlinePalette.of(ShadTheme.of(context).colorScheme);
      return RepaintBoundary(
        key: _shot,
        child: ColoredBox(
          color: ShadTheme.of(context).colorScheme.background,
          child: Wrap(
            children: [
              for (final (figure, now) in frames)
                SizedBox(
                  width: 200,
                  height: 160,
                  child: CustomPaint(painter: _Frame(figure, palette, now)),
                ),
            ],
          ),
        ),
      );
    },
  );
}

void main() {
  testWidgets('lupa at four moments of its search', (tester) async {
    final lupa = Lupa();
    await pumpAtSize(
      tester,
      Align(
        alignment: Alignment.topLeft,
        child: _sheet([(lupa, 0), (lupa, 1450), (lupa, 2100), (lupa, 3600)]),
      ),
    );
    await expectLater(find.byKey(_shot), matchesGoldenFile('goldens/lupa.png'));
  });

  testWidgets('gulungan at four turns', (tester) async {
    final reel = Gulungan();
    await pumpAtSize(
      tester,
      Align(
        alignment: Alignment.topLeft,
        child: _sheet([(reel, 0), (reel, 700), (reel, 1500), (reel, 2600)]),
      ),
    );
    await expectLater(
      find.byKey(_shot),
      matchesGoldenFile('goldens/gulungan.png'),
    );
  });

  testWidgets('tumpuk at the three beats of one turn', (tester) async {
    final stack = Tumpuk();
    await pumpAtSize(
      tester,
      Align(
        alignment: Alignment.topLeft,
        child: _sheet([(stack, 0), (stack, 500), (stack, 1000), (stack, 1800)]),
      ),
    );
    await expectLater(
      find.byKey(_shot),
      matchesGoldenFile('goldens/tumpuk.png'),
    );
  });
}
