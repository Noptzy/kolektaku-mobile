import 'package:kolektaku/features/watch/player/video_quality.dart';
import 'package:kolektaku/src/rust/dto/cues.dart';
import 'package:kolektaku/src/rust/dto/stream.dart';
import 'package:kolektaku/src/rust/dto/stream_extras.dart';

SubtitleDto sub(
  String label,
  String? language, {
  String variant = 'full',
  bool isDefault = false,
}) => SubtitleDto(
  label: label,
  language: language,
  variant: variant,
  url: 'https://s.test/$label.vtt',
  isDefault: isDefault,
);

CueDto cue(int start, int end, String text) =>
    CueDto(startMs: BigInt.from(start), endMs: BigInt.from(end), text: text);

SkipDto skip(String kind, int start, int end) =>
    SkipDto(kind: kind, startMs: BigInt.from(start), endMs: BigInt.from(end));

StreamSourceDto source(int quality, {bool isDefault = false}) =>
    StreamSourceDto(
      url: 'https://cdn.test/$quality.mp4',
      kind: 'mp4',
      quality: quality,
      label: '${quality}p',
      isDefault: isDefault,
    );

VideoQuality track(String id, int height) =>
    VideoQuality(id: id, height: height, label: '${height}p');
