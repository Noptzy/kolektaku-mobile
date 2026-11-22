import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/widgets/glass_budget.dart';

List<double> _frames(double ms, int count) => List.filled(count, ms);

void main() {
  test('percentile95 of an empty list is zero', () {
    expect(percentile95(const []), 0);
  });

  test('percentile95 picks the slow tail, not the average', () {
    final values = [..._frames(10, 94), ..._frames(60, 6)];
    expect(percentile95(values), 60);
  });

  test('fast frames never trip the budget', () {
    final budget = GlassBudget();
    budget.record(_frames(12, glassWindowFrames * 5));
    expect(budget.tripped, isFalse);
  });

  test('one slow window alone does not trip it', () {
    final budget = GlassBudget();
    budget.record(_frames(35, glassWindowFrames));
    expect(budget.tripped, isFalse);
  });

  test('two slow windows in a row trip it and notify once', () {
    final budget = GlassBudget();
    var notified = 0;
    budget.addListener(() => notified++);
    budget.record(_frames(35, glassWindowFrames * 2));
    expect(budget.tripped, isTrue);
    expect(notified, 1);
    budget.record(_frames(35, glassWindowFrames * 2));
    expect(notified, 1);
  });

  test('a good window between two slow ones resets the count', () {
    final budget = GlassBudget();
    budget
      ..record(_frames(35, glassWindowFrames))
      ..record(_frames(10, glassWindowFrames))
      ..record(_frames(35, glassWindowFrames));
    expect(budget.tripped, isFalse);
  });

  test('windows are counted across separate record calls', () {
    final budget = GlassBudget();
    for (var i = 0; i < glassWindowFrames * 2; i++) {
      budget.record([35]);
    }
    expect(budget.tripped, isTrue);
  });
}
