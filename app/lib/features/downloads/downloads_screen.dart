import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../data/providers/download_providers.dart';
import '../../src/rust/dto/downloads.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/state_view.dart';
import '../collection/confirm_sheet.dart';
import 'download_row.dart';
import 'download_starter.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key, this.starter});

  final DownloadStarter? starter;

  void _say(BuildContext context, String message) {
    if (!context.mounted) return;
    ShadToaster.of(context).show(ShadToast(description: Text(message)));
  }

  Future<void> _retry(
    BuildContext context,
    WidgetRef ref,
    DownloadDto job,
  ) async {
    _say(context, 'Mencari ulang videonya…');
    final worker =
        starter ?? DownloadStarter(gateway: ref.read(downloadGatewayProvider));
    final ok = await worker.retry(job);
    await ref.read(downloadsProvider.notifier).refresh();
    if (!ok && context.mounted) {
      _say(context, 'Videonya belum bisa ditemukan. Coba lagi nanti.');
    }
  }

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    DownloadDto job,
  ) async {
    final board = ref.read(downloadsProvider.notifier);
    if (job.phase != DownloadPhaseDto.done) {
      await board.remove(job, deleteFile: false);
      return;
    }
    final agreed = await confirmSheet(
      context,
      title: 'Hapus unduhan?',
      message:
          'File videonya juga dihapus dari HP dan tidak bisa dikembalikan.',
      confirmLabel: 'Hapus',
    );
    if (agreed) await board.remove(job, deleteFile: true);
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    DownloadDto job,
  ) async {
    final opened = await ref.read(downloadsProvider.notifier).open(job);
    if (!opened && context.mounted) {
      _say(context, 'Tersimpan di ${job.filePath ?? 'folder Unduhan'}.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(downloadsProvider);
    return ColoredBox(
      color: ShadTheme.of(context).colorScheme.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ScreenHeader(title: 'Unduhan'),
            Expanded(
              child: jobs.isEmpty
                  ? const StateView.empty(
                      key: Key('downloads-empty'),
                      title: 'Belum ada unduhan',
                      message:
                          'Tekan Unduh di halaman detail anime untuk menyimpan '
                          'episode ke HP. File tersimpan di Movies/Kolektaku.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: Spacing.xxl),
                      itemCount: jobs.length,
                      itemBuilder: (context, index) {
                        final job = jobs[index];
                        return DownloadRow(
                          key: ValueKey('download-${job.id}'),
                          job: job,
                          onCancel: () =>
                              ref.read(downloadsProvider.notifier).cancel(job),
                          onRetry: () => _retry(context, ref, job),
                          onOpen: () => _open(context, ref, job),
                          onRemove: () => _remove(context, ref, job),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
