import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/hairline/brush.dart';
import 'package:kolektaku/core/hairline/hairline_stage.dart';
import 'package:kolektaku/figures/gulungan.dart';
import 'package:kolektaku/figures/lupa.dart';
import 'package:kolektaku/figures/tumpuk.dart';
import 'package:kolektaku/widgets/hairline_loader.dart';

import '../../widgets/widget_harness.dart';

class _Probe extends HairlineFigure {
  _Probe({this.rest = 0});

  final double rest;
  final List<double> times = [];

  @override
  double get restMs => rest;

  @override
  void paint(HairlineBrush brush, double nowMs) => times.add(nowMs);
}

Widget _stage(_Probe probe, {double height = 100}) => Align(
  alignment: Alignment.topLeft,
  child: HairlineStage(create: () => probe, height: height),
);

Widget _still(Widget child) => MediaQuery(
  data: const MediaQueryData(disableAnimations: true),
  child: child,
);

void main() {
  group('HairlineStage', () {
    testWidgets('is as wide as the drawing needs for its height', (
      tester,
    ) async {
      await pumpAtSize(tester, _stage(_Probe(), height: 100));
      expect(tester.getSize(find.byType(HairlineStage)), const Size(125, 100));
    });

    testWidgets('keeps the clock running while animations are allowed', (
      tester,
    ) async {
      final probe = _Probe();
      await pumpAtSize(tester, _stage(probe));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.hasRunningAnimations, isTrue);
      expect(probe.times.length, greaterThan(2));
      for (var i = 1; i < probe.times.length; i++) {
        expect(probe.times[i], greaterThanOrEqualTo(probe.times[i - 1]));
      }
      expect(probe.times.last, greaterThan(150));
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('paints the rest pose once when animations are disabled', (
      tester,
    ) async {
      final probe = _Probe(rest: 42);
      await pumpAtSize(tester, _still(_stage(probe)));
      await tester.pump(const Duration(seconds: 5));
      expect(tester.hasRunningAnimations, isFalse);
      expect(probe.times.toSet(), {42.0});
    });

    testWidgets('stops its clock when it leaves the tree', (tester) async {
      await pumpAtSize(tester, _stage(_Probe()));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('is only decoration for screen readers', (tester) async {
      await pumpAtSize(tester, _stage(_Probe()));
      expect(
        find.descendant(
          of: find.byType(HairlineStage),
          matching: find.byType(ExcludeSemantics),
        ),
        findsWidgets,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('the real figures draw inside it without errors', (
      tester,
    ) async {
      for (final create in <HairlineFigure Function()>[
        Lupa.new,
        Gulungan.new,
        Tumpuk.new,
      ]) {
        await pumpAtSize(
          tester,
          Align(
            alignment: Alignment.topLeft,
            child: HairlineStage(create: create, height: 96),
          ),
        );
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pump(const Duration(milliseconds: 900));
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('HairlineLoader', () {
    test('makes the figure that fits each wait', () {
      expect(createFigure(HairlineKind.lupa), isA<Lupa>());
      expect(createFigure(HairlineKind.gulungan), isA<Gulungan>());
      expect(createFigure(HairlineKind.tumpuk), isA<Tumpuk>());
    });

    testWidgets('shows its message under the figure', (tester) async {
      await pumpAtSize(
        tester,
        _still(
          const Align(
            alignment: Alignment.topLeft,
            child: HairlineLoader(
              kind: HairlineKind.lupa,
              message: 'Mencari adegan...',
            ),
          ),
        ),
      );
      expect(find.text('Mencari adegan...'), findsOneWidget);
      final figure = tester.getTopLeft(find.byType(HairlineStage)).dy;
      final text = tester.getTopLeft(find.text('Mencari adegan...')).dy;
      expect(text, greaterThan(figure));
    });

    testWidgets('works without a message', (tester) async {
      await pumpAtSize(
        tester,
        _still(
          const Align(
            alignment: Alignment.topLeft,
            child: HairlineLoader(kind: HairlineKind.tumpuk),
          ),
        ),
      );
      expect(find.byType(HairlineStage), findsOneWidget);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('announces itself as a live region', (tester) async {
      await pumpAtSize(
        tester,
        _still(
          const Align(
            alignment: Alignment.topLeft,
            child: HairlineLoader(
              kind: HairlineKind.gulungan,
              message: 'Menyiapkan stream…',
            ),
          ),
        ),
      );
      final node = tester.getSemantics(find.text('Menyiapkan stream…'));
      expect(node.label, contains('Menyiapkan stream…'));
    });
  });
}
