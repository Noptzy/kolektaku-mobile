import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/watch/short_film_notice.dart';

void main() {
  group('looksTooShort', () {
    test('a video far shorter than the film is flagged', () {
      expect(
        looksTooShort(
          length: const Duration(minutes: 40),
          expectedMinutes: 117,
        ),
        isTrue,
      );
    });

    test('a video near the film length is not flagged', () {
      expect(
        looksTooShort(
          length: const Duration(minutes: 110),
          expectedMinutes: 117,
        ),
        isFalse,
      );
    });

    test('the boundary is sixty percent of the catalog length', () {
      expect(
        looksTooShort(
          length: const Duration(minutes: 72),
          expectedMinutes: 120,
        ),
        isFalse,
      );
      expect(
        looksTooShort(
          length: const Duration(minutes: 71),
          expectedMinutes: 120,
        ),
        isTrue,
      );
    });

    test('an unknown length or an unknown catalog length never flags', () {
      expect(
        looksTooShort(length: Duration.zero, expectedMinutes: 117),
        isFalse,
      );
      expect(
        looksTooShort(
          length: const Duration(minutes: 5),
          expectedMinutes: null,
        ),
        isFalse,
      );
    });

    test('short catalog durations are not judged', () {
      expect(
        looksTooShort(length: const Duration(minutes: 5), expectedMinutes: 24),
        isFalse,
      );
    });
  });
}
