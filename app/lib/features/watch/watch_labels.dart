import '../detail/episode_info_map.dart';
import 'episode_loader.dart';
import 'episodes_sheet.dart';
import 'server_sheet.dart';
import 'watch_request.dart';

String watchTitle(WatchRequest request, double current) {
  final tag = episodeTag(request.kind, current);
  return '${request.title}  ·  $tag';
}

String? episodeName(EpisodeInfos infos, double current) {
  final named = infos[current]?.title.trim() ?? '';
  return named.isEmpty ? null : named;
}

String watchEpisodeLine(
  WatchRequest request,
  EpisodeInfos infos,
  double current,
) {
  final tag = episodeTag(request.kind, current);
  final name = episodeName(infos, current);
  return name == null ? tag : '$tag  ·  $name';
}

String? playingLabel(LoadedEpisode? loaded, Map<String, String> sources) {
  if (loaded == null) return null;
  final servers = loaded.playback.servers;
  final at = servers.indexWhere((server) => server.id == loaded.serverId);
  final parts = [
    sources[loaded.playback.source],
    if (at >= 0) serverLabel(servers, at),
  ].whereType<String>().toList();
  return parts.isEmpty ? null : parts.join('  ·  ');
}

String? watchBackdrop(
  WatchRequest request,
  EpisodeInfos infos,
  double current,
) {
  final picture = infos[current]?.thumbnailUrl;
  if (picture != null && picture.isNotEmpty) return picture;
  return request.coverUrl;
}
