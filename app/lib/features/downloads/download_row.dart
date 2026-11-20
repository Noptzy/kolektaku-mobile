import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/downloads.dart';
import '../../widgets/poster.dart';
import 'download_logic.dart';

class DownloadRow extends StatelessWidget {
  const DownloadRow({
    super.key,
    required this.job,
    required this.onCancel,
    required this.onRetry,
    required this.onOpen,
    required this.onRemove,
  });

  final DownloadDto job;
  final VoidCallback onCancel;
  final VoidCallback onRetry;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final muted = theme.textTheme.muted.copyWith(fontSize: 12);
    final failed = job.phase == DownloadPhaseDto.failed;
    final status = job.bytes > BigInt.zero && isActive(job)
        ? '${phaseLabel(job)} · ${sizeLabel(job.bytes)}'
        : phaseLabel(job);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.screenGutter,
        vertical: Spacing.sm,
      ),
      child: Row(
        spacing: Spacing.md,
        children: [
          SizedBox(
            width: 52,
            child: Poster(url: job.target.coverUrl, radius: Radii.poster - 4),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  job.target.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.small.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(episodeLabel(job.target), style: muted),
                Text(
                  status,
                  key: Key('download-status-${job.id}'),
                  style: failed
                      ? muted.copyWith(color: theme.colorScheme.destructive)
                      : muted,
                ),
                if (isActive(job))
                  Padding(
                    padding: const EdgeInsets.only(top: Spacing.xs),
                    child: ShadProgress(
                      value: job.phase == DownloadPhaseDto.queued
                          ? null
                          : job.progress,
                      minHeight: 4,
                    ),
                  ),
              ],
            ),
          ),
          ..._actions(),
        ],
      ),
    );
  }

  List<Widget> _actions() {
    Widget button(String key, IconData icon, VoidCallback onPressed) =>
        ShadIconButton.ghost(
          key: Key('$key-${job.id}'),
          icon: Icon(icon, size: 20),
          onPressed: onPressed,
        );
    return [
      if (isActive(job)) button('download-cancel', LucideIcons.x, onCancel),
      if (canRetry(job))
        button('download-retry', LucideIcons.rotateCw, onRetry),
      if (job.phase == DownloadPhaseDto.done)
        button('download-open', LucideIcons.play, onOpen),
      if (!isActive(job))
        button('download-remove', LucideIcons.trash2, onRemove),
    ];
  }
}
