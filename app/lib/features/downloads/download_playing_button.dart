import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../data/providers/download_providers.dart';
import '../../platform/stream_resolver.dart';
import '../../src/rust/dto/downloads.dart';
import '../watch/watch_request.dart';
import 'download_launch.dart';
import 'download_starter.dart';

DownloadTargetDto playingTarget(WatchRequest request) => DownloadTargetDto(
  reference: request.reference,
  kind: request.kind,
  title: request.title,
  episode: request.episode,
  coverUrl: request.coverUrl,
);

class DownloadPlayingButton extends ConsumerWidget {
  const DownloadPlayingButton({
    super.key,
    required this.target,
    required this.stream,
  });

  final DownloadTargetDto target;
  final ResolvedStream? stream;

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final resolved = stream;
    if (resolved == null) return;
    final board = ref.read(downloadsProvider.notifier);
    await board.ready;
    final ok = await DownloadStarter(gateway: ref.read(downloadGatewayProvider))
        .enqueueResolved(target, resolved);
    await board.refresh();
    if (!context.mounted) return;
    final message = ok
        ? 'Episode ini masuk antrean unduhan.'
        : 'Episode ini belum bisa diunduh.';
    ShadToaster.of(context).show(ShadToast(description: Text(message)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = savedEpisodes(
      ref.watch(downloadsProvider),
      target.reference,
    ).contains(target.episode);
    return ShadButton.outline(
      key: const Key('download-playing'),
      onPressed: stream == null || saved ? null : () => _start(context, ref),
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
      gap: Spacing.xs,
      leading: Icon(saved ? LucideIcons.check : LucideIcons.download, size: 16),
      child: Flexible(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(saved ? 'Disimpan' : 'Unduh', maxLines: 1),
        ),
      ),
    );
  }
}
