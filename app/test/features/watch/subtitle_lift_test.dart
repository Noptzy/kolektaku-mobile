import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/watch/player/subtitle_overlay.dart';

void main() {
  test('visible controls push the subtitle clear above the time row', () {
    final resting = subtitleBottomPadding(lifted: false, safeBottom: 0);
    final above = subtitleBottomPadding(lifted: true, safeBottom: 0);
    expect(above, greaterThan(resting));
    expect(above, greaterThanOrEqualTo(104));
  });

  test('a system gesture bar lifts both positions by its height', () {
    expect(
      subtitleBottomPadding(lifted: true, safeBottom: 24) -
          subtitleBottomPadding(lifted: true, safeBottom: 0),
      24,
    );
    expect(
      subtitleBottomPadding(lifted: false, safeBottom: 24) -
          subtitleBottomPadding(lifted: false, safeBottom: 0),
      24,
    );
  });
}
