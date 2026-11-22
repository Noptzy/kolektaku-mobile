import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/watch/watch_resume_sheet.dart';

import 'watch_harness.dart';

const _saved = Duration(minutes: 12, seconds: 30);
const _length = Duration(minutes: 24, seconds: 10);
const _info = ResumeSheetInfo(
  title: 'Hotaru no Yomeiri',
  coverUrl: null,
  episode: 4,
);

void main() {
  group('resumeSummary', () {
    test('names the episode and where it stopped', () {
      expect(resumeSummary(_info, _saved, null), 'Episode 4 · 12:30');
    });

    test('adds the full length when it is known', () {
      expect(
        resumeSummary(_info, _saved, _length),
        'Episode 4 · 12:30 dari 24:10',
      );
    });

    test('a half episode number keeps its fraction', () {
      const half = ResumeSheetInfo(title: 'x', coverUrl: null, episode: 5.5);
      expect(resumeSummary(half, _saved, null), 'Episode 5.5 · 12:30');
    });
  });

  group('resumeShare', () {
    test('is the share of the episode already watched', () {
      expect(resumeShare(_saved, _length), closeTo(750 / 1450, 0.0001));
    });

    test('has nothing to show without a length', () {
      expect(resumeShare(_saved, null), isNull);
      expect(resumeShare(_saved, Duration.zero), isNull);
    });

    test('never passes 100%', () {
      expect(resumeShare(const Duration(hours: 2), _length), 1);
      expect(resumeShare(Duration.zero, _length), 0);
    });
  });

  group('the sheet on the watch screen', () {
    testWidgets('shows the title and where it stopped above the buttons', (
      tester,
    ) async {
      final harness = WatchHarness(resume: _saved);
      await harness.open(tester);
      final summary = find.byKey(const Key('resume-summary'));
      expect(summary, findsOneWidget);
      expect(
        find.descendant(of: summary, matching: find.textContaining('12:30')),
        findsOneWidget,
      );
      final top = tester.getTopLeft(summary).dy;
      final button = tester
          .getTopLeft(find.byKey(const Key('resume-continue')))
          .dy;
      expect(top, lessThan(button));
    });

    testWidgets('the two answers are still there and unchanged', (
      tester,
    ) async {
      final harness = WatchHarness(resume: _saved);
      await harness.open(tester);
      expect(find.text('Lanjutkan menonton?'), findsOneWidget);
      expect(find.byKey(const Key('resume-continue')), findsOneWidget);
      expect(find.byKey(const Key('resume-restart')), findsOneWidget);
      expect(find.text('Terakhir kamu berhenti di 12:30.'), findsOneWidget);
    });
  });
}
