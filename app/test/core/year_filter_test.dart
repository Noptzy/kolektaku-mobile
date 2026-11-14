import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/year_filter.dart';

void main() {
  group('YearFilter', () {
    test('an exact year accepts only that year', () {
      const filter = YearFilter.only(2020);
      expect(filter.accepts(2020), isTrue);
      expect(filter.accepts(2019), isFalse);
      expect(filter.accepts(2021), isFalse);
    });

    test('an up-to year accepts that year and every older one', () {
      const filter = YearFilter.upTo(2014);
      expect(filter.accepts(2014), isTrue);
      expect(filter.accepts(1990), isTrue);
      expect(filter.accepts(2015), isFalse);
    });

    test('an unknown year never matches', () {
      expect(const YearFilter.only(2020).accepts(null), isFalse);
      expect(const YearFilter.upTo(2020).accepts(null), isFalse);
    });

    test('ids and labels tell the two kinds apart', () {
      expect(const YearFilter.only(2020).id, '2020');
      expect(const YearFilter.only(2020).label, '2020');
      expect(const YearFilter.upTo(2014).id, 'le2014');
      expect(const YearFilter.upTo(2014).label, '2014 dan lebih lama');
    });

    test('an id parses back into the same filter', () {
      expect(YearFilter.parse('2020'), const YearFilter.only(2020));
      expect(YearFilter.parse('le2014'), const YearFilter.upTo(2014));
    });

    test('a broken id parses to nothing', () {
      expect(YearFilter.parse('abc'), isNull);
      expect(YearFilter.parse('le'), isNull);
      expect(YearFilter.parse(''), isNull);
    });

    test('equality follows year and kind', () {
      expect(const YearFilter.only(2020), const YearFilter.only(2020));
      expect(const YearFilter.only(2020) == const YearFilter.upTo(2020), false);
      expect(
        const YearFilter.only(2020).hashCode,
        const YearFilter.only(2020).hashCode,
      );
    });
  });

  group('yearOptions', () {
    test('lists the recent years newest first and one older bucket', () {
      final options = yearOptions(2026);
      expect(options.length, recentYearCount + 1);
      expect(options.first, const YearFilter.only(2026));
      expect(options[recentYearCount - 1], const YearFilter.only(2015));
      expect(options.last, const YearFilter.upTo(2014));
    });

    test('every year is covered exactly once', () {
      final options = yearOptions(2026);
      for (final year in [2026, 2020, 2015, 2014, 1999]) {
        final hits = options.where((option) => option.accepts(year)).length;
        expect(hits, 1, reason: '$year');
      }
    });
  });
}
