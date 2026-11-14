import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/detail/detail_request.dart';
import 'package:kolektaku/features/scene_search/scene_format.dart';
import 'package:kolektaku/features/scene_search/scene_launch.dart';
import 'package:kolektaku/features/scene_search/scene_state.dart';
import 'package:kolektaku/features/watch/scene_estimate_bar.dart';
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:kolektaku/src/rust/dto/scene.dart';

import '../../support/fake_scene_gateway.dart';

void main() {
  group('moments', () {
    test('minutes and seconds are padded', () {
      expect(momentLabel(0), '00:00');
      expect(momentLabel(59), '00:59');
      expect(momentLabel(279.78), '04:40');
    });

    test('an hour or more shows hours', () {
      expect(momentLabel(3700), '1:01:40');
    });

    test('nonsense never shows a negative time', () {
      expect(momentLabel(-5), '00:00');
      expect(momentLabel(double.nan), '00:00');
    });

    test('the episode and moment read as one line', () {
      expect(episodeMoment(sceneMatch(episode: 5, at: 279)), 'Ep 5 · 04:39');
      expect(episodeMoment(sceneMatch(episode: null, at: 61)), '01:01');
      expect(episodeMoment(sceneMatch(episode: 5.5, at: 61)), 'Ep 5.5 · 01:01');
    });

    test('similarity is a whole percent', () {
      expect(similarityLabel(0.9922), '99%');
      expect(similarityLabel(0.805), '81%');
    });

    test('the quota line names the number', () {
      expect(quotaLabel(93), 'Sisa pencarian gambar hari ini: 93');
    });
  });

  group('watchRequestFor', () {
    SceneLaunch launch({SceneMatchDto? match, SceneTargetDto? target}) =>
        SceneLaunch(
          target: target ?? watchTarget(episode: 3, start: 97.5),
          match: match ?? sceneMatch(at: 100.5, duration: 1418),
        );

    test('opens the right episode at the moment three seconds early', () {
      final request = watchRequestFor(launch());
      expect(request.episode, 3);
      expect(request.startAt, const Duration(milliseconds: 97500));
      expect(request.kind, MediaKindDto.anime);
      expect(request.reference.id, BigInt.from(21034));
      expect(request.title, 'Gochuumon wa Usagi desu ka??');
    });

    test('keeps the estimate for the watch screen', () {
      final estimate = watchRequestFor(launch()).scene!;
      expect(estimate.at, const Duration(milliseconds: 100500));
      expect(estimate.sourceLength, const Duration(seconds: 1418));
    });

    test('a missing title and length fall back safely', () {
      final request = watchRequestFor(
        launch(match: sceneMatch(title: null, duration: null)),
      );
      expect(request.title, 'Anime');
      expect(request.scene!.sourceLength, isNull);
    });
  });

  group('detailRequestFor', () {
    test('a title nobody has carries the note', () {
      final request = detailRequestFor(
        SceneLaunch(target: detailTarget(), match: sceneMatch()),
      );
      expect(request.notice, notAvailableNotice);
      expect(request.kind, MediaKindDto.anime);
    });

    test('a missing episode number carries no note', () {
      final request = detailRequestFor(
        SceneLaunch(
          target: detailTarget(reason: DetailReasonDto.noEpisode),
          match: sceneMatch(),
        ),
      );
      expect(request.notice, isNull);
    });

    test('the note takes part in request identity', () {
      final base = DetailRequest(
        kind: MediaKindDto.anime,
        reference: watchRequestFor(
          SceneLaunch(target: watchTarget(), match: sceneMatch()),
        ).reference,
      );
      final noted = DetailRequest(
        kind: base.kind,
        reference: base.reference,
        notice: 'x',
      );
      expect(base == noted, isFalse);
    });
  });

  group('lengthsDiffer', () {
    test('a minute or less apart is fine', () {
      expect(
        lengthsDiffer(
          const Duration(seconds: 1440),
          const Duration(seconds: 1418),
        ),
        isFalse,
      );
      expect(
        lengthsDiffer(
          const Duration(seconds: 1478),
          const Duration(seconds: 1418),
        ),
        isFalse,
      );
    });

    test('more than a minute apart is a warning', () {
      expect(
        lengthsDiffer(
          const Duration(seconds: 1500),
          const Duration(seconds: 1418),
        ),
        isTrue,
      );
      expect(
        lengthsDiffer(
          const Duration(seconds: 1300),
          const Duration(seconds: 1418),
        ),
        isTrue,
      );
    });

    test('unknown lengths never warn', () {
      expect(
        lengthsDiffer(Duration.zero, const Duration(seconds: 1418)),
        isFalse,
      );
      expect(lengthsDiffer(const Duration(seconds: 1500), null), isFalse);
    });
  });
}
