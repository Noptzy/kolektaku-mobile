import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/settings_providers.dart';
import '../../data/providers/source_providers.dart';
import '../../src/rust/dto/media.dart';
import '../../src/rust/dto/sources.dart';
import '../detail/detail_providers.dart';
import '../detail/detail_request.dart';
import '../detail/episode_info_map.dart';
import '../settings/settings_logic.dart';
import 'watch_request.dart';
import 'watch_screen.dart';

Map<String, String> _namesOf(List<SourceStatusDto> statuses) {
  return {
    for (final entry in numberedSources(statuses, MediaKindDto.anime))
      entry.status.id: sourceLabel(MediaKindDto.anime, entry.number),
  };
}

Map<String, String> _summariesOf(List<SourceStatusDto> statuses) {
  return {
    for (final status in statuses)
      if (status.summary.trim().isNotEmpty) status.id: status.summary.trim(),
  };
}

class WatchRoute extends ConsumerWidget {
  const WatchRoute({super.key, required this.request});

  final WatchRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statuses = ref.watch(sourceStatusProvider).value ?? const [];
    final detail = ref.watch(
      detailProvider(
        DetailRequest(kind: request.kind, reference: request.reference),
      ),
    );
    return WatchScreen(
      request: request,
      episodeInfos: episodeInfosOf(detail.value),
      episodeArt: artOf(detail.value),
      settings: ref.watch(currentSettingsProvider),
      sourceNames: _namesOf(statuses),
      sourceSummaries: _summariesOf(statuses),
      linkedSources: [
        for (final link
            in detail.value?.catalog?.sources ?? const <SourceLinkDto>[])
          link.source,
      ],
    );
  }
}
