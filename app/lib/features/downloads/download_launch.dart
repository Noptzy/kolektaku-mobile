import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../data/providers/download_providers.dart';
import '../../src/rust/dto/downloads.dart';
import '../../src/rust/dto/media.dart';
import '../../src/rust/dto/sources.dart';
import '../../widgets/swipe_sheet.dart';
import '../detail/detail_info.dart';
import '../detail/detail_request.dart';
import '../home/resume_card.dart';
import 'download_logic.dart';
import 'download_starter.dart';
import 'episode_picker.dart';

class DownloadSeed {
  const DownloadSeed({
    required this.reference,
    required this.title,
    this.coverUrl,
    this.preferredSource,
  });

  final MediaRefDto reference;
  final String title;
  final String? coverUrl;
  final String? preferredSource;

  DownloadTargetDto target(double episode) => DownloadTargetDto(
    reference: reference,
    kind: MediaKindDto.anime,
    title: title,
    episode: episode,
    coverUrl: coverUrl,
  );
}

Set<double> savedEpisodes(List<DownloadDto> jobs, MediaRefDto reference) => {
  for (final job in jobs)
    if (job.target.reference == reference &&
        (isActive(job) || job.phase == DownloadPhaseDto.done))
      job.target.episode,
};

String startedMessage(StartReport report) {
  final failed = report.failed;
  if (report.queued == 0) {
    return 'Videonya belum bisa ditemukan. Coba lagi nanti.';
  }
  final base = '${report.queued} episode masuk antrean unduhan';
  if (failed.isEmpty) return '$base.';
  final missed = failed.map(unitText).join(', ');
  return '$base. Episode $missed belum bisa ditemukan.';
}

void _say(BuildContext context, String message) {
  if (!context.mounted) return;
  ShadToaster.of(context).show(ShadToast(description: Text(message)));
}

Future<void> startDownloads(
  BuildContext context,
  WidgetRef ref,
  DownloadSeed seed,
  List<UnitDto> units,
) async {
  final board = ref.read(downloadsProvider.notifier);
  final starter = DownloadStarter(gateway: ref.read(downloadGatewayProvider));
  _say(context, 'Menyiapkan ${units.length} episode…');
  await board.ready;
  final report = await starter.start(
    [for (final unit in units) seed.target(unit.number)],
    preferred: seed.preferredSource,
    onStep: (done, total) => unawaited(board.refresh()),
  );
  await board.refresh();
  if (context.mounted) _say(context, startedMessage(report));
}

Future<void> openDownloadPicker(
  BuildContext context,
  WidgetRef ref,
  DownloadSeed seed,
  List<UnitDto> units,
) async {
  final saved = savedEpisodes(ref.read(downloadsProvider), seed.reference);
  final chosen = await showSwipeSheet<List<UnitDto>>(
    context: context,
    builder: (sheetContext) => ShadSheet(
      title: const Text('Unduh episode'),
      description: const Text(
        'Video dan subtitle (sesuai Pengaturan › Unduhan) disimpan sebagai '
        'satu file MKV di Movies/Kolektaku.',
      ),
      child: EpisodePicker(
        units: units,
        downloaded: saved,
        onConfirm: (picked) => Navigator.of(sheetContext).pop(picked),
      ),
    ),
  );
  if (chosen == null || chosen.isEmpty || !context.mounted) return;
  await startDownloads(context, ref, seed, chosen);
}

ValueChanged<List<UnitDto>>? downloadPickerFor(
  BuildContext context,
  WidgetRef ref, {
  required MediaKindDto kind,
  required DownloadSeed seed,
}) {
  if (kind != MediaKindDto.anime) return null;
  return (units) => openDownloadPicker(context, ref, seed, units);
}

ValueChanged<List<UnitDto>>? detailDownload(
  BuildContext context,
  WidgetRef ref,
  DetailRequest request,
  DetailInfo info,
) => downloadPickerFor(
  context,
  ref,
  kind: request.kind,
  seed: DownloadSeed(
    reference: request.reference,
    title: info.title,
    coverUrl: info.coverUrl,
  ),
);
