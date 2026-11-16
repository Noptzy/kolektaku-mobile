import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/screen_harness.dart';
import 'overlap_finder.dart';

const phoneSizes = [Size(360, 780), Size(390, 844), Size(412, 915)];
const textScales = [1.0, 1.3];

typedef Prepare = void Function(ScreenHarness harness);

String _describe(FlutterErrorDetails details) {
  final lines = details.toString().split('\n');
  final at = lines.indexWhere((line) => line.contains('error-causing widget'));
  final widget = at < 0
      ? ''
      : lines.skip(at).take(4).map((l) => l.trim()).join(' ');
  final head = details.exceptionAsString().split('\n').first;
  return '$head [$widget]';
}

Future<void> auditScreen(
  WidgetTester tester, {
  required String name,
  required Widget Function() screen,
  Prepare? prepare,
  List<Size> sizes = phoneSizes,
  List<double> scales = textScales,
  Future<void> Function(WidgetTester tester)? after,
}) async {
  final problems = <String>[];
  for (final size in sizes) {
    for (final scale in scales) {
      final label =
          '$name @ ${size.width.round()}x${size.height.round()} '
          'huruf x$scale';
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      final caught = <FlutterErrorDetails>[];
      final original = FlutterError.onError;
      FlutterError.onError = caught.add;
      try {
        final harness = ScreenHarness();
        prepare?.call(harness);
        await harness.pump(tester, screen(), size: size);
        if (after != null) await after(tester);
        problems.addAll(caught.map((error) => '$label: ${_describe(error)}'));
        problems.addAll(
          overlappingTargets(tester).map((found) => '$label: $found'),
        );
        await tester.pumpWidget(const SizedBox());
      } finally {
        FlutterError.onError = original;
      }
    }
  }
  expect(problems.toSet().toList(), isEmpty);
}
