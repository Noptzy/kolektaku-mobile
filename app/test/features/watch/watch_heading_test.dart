import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/watch/watch_heading.dart';
import 'package:kolektaku/features/watch/watch_labels.dart';
import 'package:kolektaku/features/watch/watch_request.dart';
import 'package:kolektaku/src/rust/dto/episodes.dart';
import 'package:kolektaku/src/rust/dto/media.dart';

import '../../support/screen_harness.dart';
import 'watch_fixtures.dart';

WatchRequest request({MediaKindDto kind = MediaKindDto.anime}) => WatchRequest(
  reference: reference,
  kind: kind,
  title: 'Shingeki no Kyojin',
  episode: 25,
);

Future<void> show(
  WidgetTester tester, {
  String? synopsis,
  String line = 'Ep 25  ·  Pertarungan',
}) {
  return ScreenHarness().pump(
    tester,
    Align(
      alignment: Alignment.topCenter,
      child: WatchHeading(
        title: 'Shingeki no Kyojin',
        episodeLine: line,
        synopsis: synopsis,
      ),
    ),
  );
}

void main() {
  group('episode line', () {
    test('adds the episode name after the number', () {
      final infos = {
        25.0: const EpisodeInfoDto(number: 25, title: 'Pertarungan'),
      };
      expect(watchEpisodeLine(request(), infos, 25), 'Ep 25  ·  Pertarungan');
      expect(episodeName(infos, 25), 'Pertarungan');
    });

    test('is only the number when the episode has no name', () {
      final infos = {25.0: const EpisodeInfoDto(number: 25, title: '  ')};
      expect(watchEpisodeLine(request(), infos, 25), 'Ep 25');
      expect(watchEpisodeLine(request(), const {}, 25), 'Ep 25');
      expect(episodeName(const {}, 25), isNull);
    });

    test('a chapter is called Ch', () {
      expect(
        watchEpisodeLine(request(kind: MediaKindDto.manga), const {}, 3),
        'Ch 3',
      );
    });
  });

  group('WatchHeading', () {
    testWidgets('shows the title with the episode line under it', (
      tester,
    ) async {
      await show(tester);
      final title = tester.getTopLeft(find.byKey(const Key('watch-title')));
      final line = tester.getTopLeft(
        find.byKey(const Key('watch-episode-line')),
      );
      expect(find.text('Shingeki no Kyojin'), findsOneWidget);
      expect(find.text('Ep 25  ·  Pertarungan'), findsOneWidget);
      expect(line.dy, greaterThan(title.dy));
    });

    testWidgets('has no synopsis row when there is none', (tester) async {
      await show(tester);
      expect(find.byKey(const Key('watch-synopsis')), findsNothing);
      await show(tester, synopsis: '   ');
      expect(find.byKey(const Key('watch-synopsis')), findsNothing);
    });

    testWidgets('the synopsis opens in full in a bottom sheet', (tester) async {
      final text = List.filled(40, 'Cerita yang panjang.').join(' ');
      await show(tester, synopsis: text);
      expect(find.byKey(const Key('synopsis-full')), findsNothing);
      await tester.tap(find.byKey(const Key('watch-synopsis')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('synopsis-full')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('synopsis-full'))).data,
        text,
      );
    });
  });
}
