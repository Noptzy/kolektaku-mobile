import '../detail/episode_row.dart';

double? scrollTargetFor({
  required double headerHeight,
  required int index,
  required double offset,
  required double viewport,
  required double maxExtent,
}) {
  final top = headerHeight + index * episodeRowHeight;
  final bottom = top + episodeRowHeight;
  if (top >= offset && bottom <= offset + viewport) return null;
  final wanted = top - viewport * 0.25;
  return wanted.clamp(0.0, maxExtent < 0 ? 0.0 : maxExtent);
}
