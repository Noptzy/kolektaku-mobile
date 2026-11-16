import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/novel_reader/highlight_ranges.dart';

void main() {
  const text = 'Join the Classics Club. It is a humanities club.';

  group('locateMark', () {
    test('a mark whose text is still where it was stays there', () {
      final mark = locateMark(
        id: 1,
        text: text,
        start: 9,
        end: 22,
        quote: 'Classics Club',
      );
      expect(mark, (id: 1, start: 9, end: 22));
    });

    test('a mark whose paragraph changed is found again by its quote', () {
      final mark = locateMark(
        id: 2,
        text: 'New words. $text',
        start: 9,
        end: 22,
        quote: 'Classics Club',
      );
      expect(mark?.start, 'New words. Join the '.length);
    });

    test('a quote that is gone is dropped', () {
      expect(
        locateMark(id: 3, text: text, start: 0, end: 3, quote: 'vanished'),
        isNull,
      );
      expect(
        locateMark(id: 4, text: text, start: 0, end: 3, quote: ''),
        isNull,
      );
    });
  });

  group('segmentsOf', () {
    test('plain text is one piece', () {
      expect(segmentsOf('abc', const []), [
        (start: 0, end: 3, highlightId: null),
      ]);
    });

    test('a mark splits the text into before, marked and after', () {
      final pieces = segmentsOf(text, [(id: 7, start: 9, end: 22)]);
      expect(pieces.map((p) => (p.start, p.end, p.highlightId)).toList(), [
        (0, 9, null),
        (9, 22, 7),
        (22, text.length, null),
      ]);
    });

    test('overlapping marks never repeat text', () {
      final pieces = segmentsOf(text, [
        (id: 1, start: 0, end: 10),
        (id: 2, start: 5, end: 15),
      ]);
      expect(pieces[0], (start: 0, end: 10, highlightId: 1));
      expect(pieces[1], (start: 10, end: 15, highlightId: 2));
      final covered = pieces.fold<int>(0, (sum, p) => sum + p.end - p.start);
      expect(covered, text.length);
    });

    test('marks given out of order still read left to right', () {
      final pieces = segmentsOf(text, [
        (id: 2, start: 24, end: 30),
        (id: 1, start: 0, end: 4),
      ]);
      final ids = pieces
          .where((p) => p.highlightId != null)
          .map((p) => p.highlightId);
      expect(ids, [1, 2]);
    });
  });

  group('selection', () {
    test('the selected words are found inside the paragraph', () {
      expect(rangeOfSelection(text, 'Classics Club'), (start: 9, end: 22));
      expect(rangeOfSelection(text, '  Classics Club '), (start: 9, end: 22));
    });

    test('a selection that spans paragraphs or is empty is refused', () {
      expect(rangeOfSelection(text, 'a\nb'), isNull);
      expect(rangeOfSelection(text, '   '), isNull);
      expect(rangeOfSelection(text, 'not in the text'), isNull);
    });

    test(
      'only a single paragraph up to one thousand letters is highlightable',
      () {
        expect(isHighlightable('short'), isTrue);
        expect(isHighlightable('a\nb'), isFalse);
        expect(isHighlightable(''), isFalse);
        expect(isHighlightable('x' * 1001), isFalse);
        expect(isHighlightable('x' * 1000), isTrue);
      },
    );
  });
}
