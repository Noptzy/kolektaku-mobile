import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../src/rust/dto/stream.dart';
import '../../../src/rust/dto/stream_extras.dart';
import 'subtitle_logic.dart';
import 'video_quality.dart';

const playbackSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

String speedLabel(double speed) => '${speed}x';

Future<void> _pick<T>({
  required BuildContext context,
  required String title,
  required List<(String, T)> options,
  required T selected,
  required ValueChanged<T> onPicked,
}) {
  return showShadSheet<void>(
    context: context,
    side: ShadSheetSide.bottom,
    builder: (sheet) => ShadSheet(
      title: Text(title),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheet).height * 0.6,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (label, value) in options)
                ShadButton.ghost(
                  key: Key('option-$label'),
                  onPressed: () {
                    Navigator.of(sheet).pop();
                    onPicked(value);
                  },
                  child: Flexible(
                    child: Text(
                      value == selected ? '$label  •' : label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> pickSpeed(
  BuildContext context, {
  required double current,
  required ValueChanged<double> onPicked,
}) {
  return _pick<double>(
    context: context,
    title: 'Kecepatan',
    options: [for (final speed in playbackSpeeds) (speedLabel(speed), speed)],
    selected: current,
    onPicked: onPicked,
  );
}

Future<void> pickQuality(
  BuildContext context, {
  required List<StreamSourceDto> sources,
  required int current,
  required ValueChanged<int> onPicked,
}) {
  return _pick<int>(
    context: context,
    title: 'Kualitas',
    options: [for (var i = 0; i < sources.length; i++) (sources[i].label, i)],
    selected: current,
    onPicked: onPicked,
  );
}

Future<void> pickTrack(
  BuildContext context, {
  required List<VideoQuality> tracks,
  required String? current,
  required ValueChanged<String?> onPicked,
}) {
  return _pick<String?>(
    context: context,
    title: 'Resolusi',
    options: [
      ('Otomatis', null),
      for (final track in tracks) (track.label, track.id),
    ],
    selected: current,
    onPicked: onPicked,
  );
}

Future<void> pickSubtitle(
  BuildContext context, {
  required List<SubtitleDto> tracks,
  required SubtitleDto? current,
  required ValueChanged<SubtitleDto?> onPicked,
}) {
  final ordered = orderedSubtitles(tracks);
  final titles = [for (final track in ordered) subtitleTitle(track)];
  return _pick<SubtitleDto?>(
    context: context,
    title: 'Subtitle',
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
