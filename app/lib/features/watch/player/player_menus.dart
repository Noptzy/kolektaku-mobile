import 'package:flutter/widgets.dart';

import '../../../src/rust/dto/stream.dart';
import '../../../src/rust/dto/stream_extras.dart';
import 'option_list.dart';
import 'subtitle_logic.dart';
import 'video_quality.dart';

const playbackSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

String speedLabel(double speed) => '${speed}x';

Widget speedOptions({
  required double current,
  required ValueChanged<double> onPicked,
}) {
  return OptionList<double>(
    options: [for (final speed in playbackSpeeds) (speedLabel(speed), speed)],
    selected: current,
    onPicked: onPicked,
  );
}

Widget qualityOptions({
  required List<StreamSourceDto> sources,
  required int current,
  required ValueChanged<int> onPicked,
}) {
  return OptionList<int>(
    options: [for (var i = 0; i < sources.length; i++) (sources[i].label, i)],
    selected: current,
    onPicked: onPicked,
  );
}

Widget trackOptions({
  required List<VideoQuality> tracks,
  required String? current,
  required ValueChanged<String?> onPicked,
}) {
  return OptionList<String?>(
    options: [
      ('Otomatis', null),
      for (final track in tracks) (track.label, track.id),
    ],
    selected: current,
    onPicked: onPicked,
  );
}

Widget subtitleOptions({
  required List<SubtitleDto> tracks,
  required SubtitleDto? current,
  required ValueChanged<SubtitleDto?> onPicked,
}) {
  final ordered = orderedSubtitles(tracks);
  final titles = [for (final track in ordered) subtitleTitle(track)];
  return OptionList<SubtitleDto?>(
    options: [
      ('Mati', null),
      for (var i = 0; i < ordered.length; i++)
        (
          titles.where((title) => title == titles[i]).length > 1
              ? ordered[i].label
              : titles[i],
          ordered[i],
        ),
    ],
    selected: current,
    onPicked: onPicked,
  );
}
