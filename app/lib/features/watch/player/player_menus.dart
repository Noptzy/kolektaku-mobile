import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/translation_labels.dart';
import '../../../src/rust/dto/settings.dart';
import '../../../src/rust/dto/stream.dart';
import '../../../src/rust/dto/stream_extras.dart';
import '../../../widgets/option_list.dart';
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
  String? currentLabel,
  Widget? originalToggle,
}) {
  final ordered = orderedSubtitles(tracks);
  final titles = [for (final track in ordered) subtitleTitle(track)];
  String labelOf(int index) {
    if (ordered[index] == current && currentLabel != null) return currentLabel;
    final repeated = titles.where((title) => title == titles[index]).length > 1;
    return repeated ? ordered[index].label : titles[index];
  }

  return OptionList<SubtitleDto?>(
    options: [
      ('Mati', null),
      for (var i = 0; i < ordered.length; i++) (labelOf(i), ordered[i]),
    ],
    selected: current,
    onPicked: onPicked,
    footer: [?originalToggle],
  );
}

Widget originalTextToggle({
  required bool showingOriginal,
  required VoidCallback onPressed,
}) {
  return ShadButton.outline(
    key: const Key('toggle-original-subtitle'),
    onPressed: onPressed,
    child: Text(
      showingOriginal ? 'Tampilkan terjemahan' : 'Tampilkan teks asli',
    ),
  );
}

Widget translateNowButton({
  required TranslationLanguageDto target,
  required VoidCallback onPressed,
}) {
  return ShadButton.outline(
    key: const Key('translate-subtitle-now'),
    onPressed: onPressed,
    child: Flexible(
      child: Text(
        'Terjemahkan ke ${translationLanguageNames[target]}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  );
}
