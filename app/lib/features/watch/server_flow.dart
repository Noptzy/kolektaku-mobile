import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../widgets/sheet_scroll.dart';
import 'server_choice.dart';
import 'server_options.dart';
import 'server_sheet.dart';
import 'watch_controller.dart';

String? currentAudioLabel(WatchController controller) {
  final loaded = controller.loaded;
  if (loaded == null) return null;
  final servers = loaded.playback.servers;
  final index = servers.indexWhere((server) => server.id == loaded.serverId);
  return index < 0 ? null : serverLabel(servers, index);
}

List<OtherSource> _othersOf(
  WatchController controller, {
  required List<String> linkedSources,
  required Map<String, String> sourceNames,
  required Map<String, String> sourceSummaries,
}) {
  return otherSourcesOf(
    linked: linkedSources,
    current: controller.loaded?.playback.source,
    names: sourceNames,
    summaries: sourceSummaries,
  );
}

Future<void> applyServerChoice(
  WatchController controller,
  ServerChoice? choice,
) async {
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
    others: _othersOf(
      controller,
      linkedSources: linkedSources,
      sourceNames: sourceNames,
      sourceSummaries: sourceSummaries,
    ),
  );
  await applyServerChoice(controller, choice);
}

Widget serverPage(
  WatchController controller, {
  required List<String> linkedSources,
  required Map<String, String> sourceNames,
  required Map<String, String> sourceSummaries,
  required ValueChanged<ServerChoice> onChoice,
}) {
  final loaded = controller.loaded;
  if (loaded == null) return const SizedBox.shrink();
  final servers = loaded.playback.servers;
  return SheetScroll(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Builder(
          builder: (context) => Text(
            serverHint(servers),
            style: ShadTheme.of(context).textTheme.muted.copyWith(fontSize: 12),
          ),
        ),
        const SizedBox(height: Spacing.sm),
        ServerOptions(
          servers: servers,
          current: loaded.serverId,
          others: _othersOf(
            controller,
            linkedSources: linkedSources,
            sourceNames: sourceNames,
            sourceSummaries: sourceSummaries,
          ),
          onChoice: onChoice,
        ),
      ],
    ),
  );
}
