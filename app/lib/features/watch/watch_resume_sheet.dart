import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_text.dart';
import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/media.dart';
import '../../widgets/poster.dart';
import '../../widgets/swipe_sheet.dart';
import '../home/resume_card.dart';
import 'player/clock_format.dart';
import 'watch_controller.dart';

const _thumbWidth = 112.0;
const _thumbAspect = 16 / 9;

String resumeQuestion(Duration position) =>
    'Terakhir kamu berhenti di ${formatClock(position)}.';

class ResumeSheetInfo {
  const ResumeSheetInfo({
    required this.title,
    required this.coverUrl,
    required this.episode,
  });

  final String title;
  final String? coverUrl;
  final double episode;
}

String resumeSummary(
  ResumeSheetInfo info,
  Duration position,
  Duration? length,
) {
  final unit = resumeMeta(MediaKindDto.anime, info.episode);
  final spot = formatClock(position);
  if (length == null) return '$unit · $spot';
  return '$unit · $spot dari ${formatClock(length)}';
}

double? resumeShare(Duration position, Duration? length) {
  if (length == null || length <= Duration.zero) return null;
  return (position.inMilliseconds / length.inMilliseconds).clamp(0.0, 1.0);
}

Future<bool?> showResumeSheet(
  BuildContext context, {
  required Duration position,
  Duration? length,
  ResumeSheetInfo? info,
}) {
  return showSwipeSheet<bool>(
    context: context,
    builder: (sheet) => ShadSheet(
      title: const Text('Lanjutkan menonton?'),
      description: Text(resumeQuestion(position)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Spacing.sm,
          children: [
            if (info != null)
              Padding(
                padding: const EdgeInsets.only(bottom: Spacing.sm),
                child: _Summary(info: info, position: position, length: length),
              ),
            ShadButton(
              key: const Key('resume-continue'),
              onPressed: () => Navigator.of(sheet).pop(true),
              child: Text('Lanjut dari ${formatClock(position)}'),
            ),
            ShadButton.outline(
              key: const Key('resume-restart'),
              onPressed: () => Navigator.of(sheet).pop(false),
              child: const Text('Mulai dari awal'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.info,
    required this.position,
    required this.length,
  });

  final ResumeSheetInfo info;
  final Duration position;
  final Duration? length;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final share = resumeShare(position, length);
    return Row(
      key: const Key('resume-summary'),
      spacing: Spacing.md,
      children: [
        SizedBox(
          width: _thumbWidth,
          child: Poster(
            url: info.coverUrl,
            aspectRatio: _thumbAspect,
            radius: 10,
            overlays: [
              if (share != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ShadProgress(
                    value: share,
                    minHeight: 4,
                    borderRadius: BorderRadius.zero,
                    innerBorderRadius: BorderRadius.zero,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: Spacing.xs,
            children: [
              Text(
                info.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.cardTitle.copyWith(fontSize: 15),
              ),
              Text(
                resumeSummary(info, position, length),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.cardMeta.copyWith(
                  color: theme.colorScheme.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ResumeAsker {
  bool _asking = false;

  void follow(
    BuildContext Function() context,
    bool Function() mounted,
    WatchController controller,
  ) {
    final position = controller.resumePrompt;
    if (position == null || _asking) return;
    _asking = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted()) return;
      final length = controller.session?.engine.snapshot.value.duration;
      final choice = await showResumeSheet(
        context(),
        position: position,
        length: length != null && length > Duration.zero ? length : null,
        info: ResumeSheetInfo(
          title: controller.request.title,
          coverUrl: controller.request.coverUrl,
          episode: controller.current,
        ),
      );
      _asking = false;
      await controller.chooseResume(resume: choice ?? true);
    });
  }
}
