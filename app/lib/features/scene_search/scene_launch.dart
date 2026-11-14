import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../core/routes.dart';
import '../../src/rust/dto/media.dart';
import '../../src/rust/dto/scene.dart';
import '../../widgets/summary_card.dart';
import '../detail/detail_request.dart';
import '../watch/watch_request.dart';
import 'scene_state.dart';

const notAvailableNotice = 'Belum tersedia untuk ditonton.';

Duration _seconds(double value) =>
    Duration(milliseconds: (value * 1000).round());

WatchRequest watchRequestFor(SceneLaunch launch) {
  final target = launch.target;
  final match = launch.match;
  final length = match.durationSecs;
  return WatchRequest(
    reference: catalogRef(target.mediaId),
    kind: MediaKindDto.anime,
    title: match.title ?? 'Anime',
    episode: target.episode ?? 1,
    startAt: _seconds(target.startSecs ?? 0),
    scene: SceneEstimate(
      at: _seconds(match.atSecs),
      sourceLength: length == null ? null : _seconds(length),
    ),
  );
}

DetailRequest detailRequestFor(SceneLaunch launch) {
  final target = launch.target;
  return DetailRequest(
    kind: MediaKindDto.anime,
    reference: catalogRef(target.mediaId),
    notice: target.reason == DetailReasonDto.notAvailable
        ? notAvailableNotice
        : null,
  );
}

Future<void> launchScene(BuildContext context, SceneLaunch launch) async {
  if (launch.target.kind == SceneTargetKind.watch) {
    await context.push(Routes.watch, extra: watchRequestFor(launch));
  } else {
    await context.push(Routes.detail, extra: detailRequestFor(launch));
  }
}
