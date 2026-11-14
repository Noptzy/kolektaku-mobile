import '../../../src/rust/dto/settings.dart';
import '../../../src/rust/dto/stream.dart';

class VideoQuality {
  const VideoQuality({
    required this.id,
    required this.height,
    required this.label,
  });

  final String id;
  final int height;
  final String label;

  @override
  bool operator ==(Object other) =>
      other is VideoQuality && other.id == id && other.height == height;

  @override
  int get hashCode => Object.hash(id, height);
}

typedef RawTrack = ({String id, int? height, int? bitrate});

List<VideoQuality> qualityChoices(Iterable<RawTrack> tracks) {
  final best = <int, RawTrack>{};
  for (final track in tracks) {
    final height = track.height;
    if (height == null || height <= 0) continue;
    final known = best[height];
    if (known == null || (track.bitrate ?? 0) > (known.bitrate ?? 0)) {
      best[height] = track;
    }
  }
  final heights = best.keys.toList()..sort((a, b) => b.compareTo(a));
  return [
    for (final height in heights)
      VideoQuality(id: best[height]!.id, height: height, label: '${height}p'),
  ];
}

int? heightCap(QualityDto preference) => switch (preference) {
  QualityDto.auto => null,
  QualityDto.p1080 => 1080,
  QualityDto.p720 => 720,
  QualityDto.p480 => 480,
  QualityDto.p360 => 360,
};

VideoQuality? preferredTrack(List<VideoQuality> tracks, QualityDto preference) {
  final cap = heightCap(preference);
  if (cap == null || tracks.length < 2) return null;
  final sorted = [...tracks]..sort((a, b) => b.height.compareTo(a.height));
  for (final track in sorted) {
    if (track.height <= cap) return track;
  }
  return sorted.last;
}

int preferredSourceIndex(List<StreamSourceDto> sources, QualityDto preference) {
  final fallback = sources.indexWhere((source) => source.isDefault);
  final start = fallback < 0 ? 0 : fallback;
  final cap = heightCap(preference);
  if (cap == null || sources.length < 2) return start;
  int? best;
  int? lowest;
  for (var i = 0; i < sources.length; i++) {
    final quality = sources[i].quality;
    if (quality <= 0) continue;
    if (lowest == null || quality < sources[lowest].quality) lowest = i;
    if (quality <= cap && (best == null || quality > sources[best].quality)) {
      best = i;
    }
  }
  return best ?? lowest ?? start;
}
