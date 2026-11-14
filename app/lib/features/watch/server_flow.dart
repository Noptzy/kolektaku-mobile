import 'package:flutter/widgets.dart';

import 'server_sheet.dart';
import 'watch_controller.dart';

String? currentAudioLabel(WatchController controller) {
  final loaded = controller.loaded;
  if (loaded == null) return null;
  final servers = loaded.playback.servers;
  final index = servers.indexWhere((server) => server.id == loaded.serverId);
  return index < 0 ? null : serverLabel(servers, index);
}

Future<void> changeServer(
  BuildContext context,
  WatchController controller, {
  required List<String> linkedSources,
  required Map<String, String> sourceNames,
  required Map<String, String> sourceSummaries,
}) async {
  final loaded = controller.loaded;
  if (loaded == null) return;
  final choice = await showServerSheet(
    context,
    servers: loaded.playback.servers,
    current: loaded.serverId,
    others: otherSourcesOf(
      linked: linkedSources,
      current: loaded.playback.source,
      names: sourceNames,
      summaries: sourceSummaries,
    ),
  );
  switch (choice) {
    case PickServer(:final id):
      await controller.useServer(id);
    case UseSource(:final id):
      await controller.useSource(id);
    case TryOtherSource():
      await controller.tryOtherSource();
    case null:
      return;
  }
}
