import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import 'player/playback_engine.dart';
import 'player/player_session.dart';
import 'watch_request.dart';

const _shift = Duration(seconds: 10);
const _lengthTolerance = Duration(seconds: 60);

bool lengthsDiffer(Duration video, Duration? source) {
  if (source == null || video <= Duration.zero) return false;
  return (video - source).abs() > _lengthTolerance;
}

class SceneEstimateBar extends StatelessWidget {
  const SceneEstimateBar({
    super.key,
    required this.session,
    required this.estimate,
    required this.onOthers,
  });

  final PlayerSession session;
  final SceneEstimate estimate;
  final VoidCallback onOthers;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.all(Spacing.lg),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.card,
          borderRadius: Radii.cardShape,
          border: Border.all(color: theme.colorScheme.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: ValueListenableBuilder<PlaybackSnapshot>(
            valueListenable: session.engine.snapshot,
            builder: (context, snapshot, child) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: Spacing.sm,
              children: [
                Text(
                  'Perkiraan posisi',
                  style: theme.textTheme.p.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Menitnya mengikuti berkas sumber gambar, jadi bisa meleset beberapa detik.',
                  style: theme.textTheme.muted,
                ),
                if (lengthsDiffer(snapshot.duration, estimate.sourceLength))
                  const ShadAlert(
                    key: Key('length-warning'),
                    description: Text(
                      'Durasi video ini berbeda jauh dari sumber gambar, posisinya mungkin meleset.',
                    ),
                  ),
                Wrap(
                  spacing: Spacing.sm,
                  runSpacing: Spacing.sm,
                  children: [
                    ShadButton.outline(
                      key: const Key('estimate-back'),
                      size: ShadButtonSize.sm,
                      onPressed: () => session.skip(-_shift),
                      child: const Text('-10 dtk'),
                    ),
                    ShadButton.outline(
                      key: const Key('estimate-forward'),
                      size: ShadButtonSize.sm,
                      onPressed: () => session.skip(_shift),
                      child: const Text('+10 dtk'),
                    ),
                    ShadButton.ghost(
                      key: const Key('estimate-others'),
                      size: ShadButtonSize.sm,
                      onPressed: onOthers,
                      child: const Flexible(
                        child: Text(
                          'Bukan ini? Lihat hasil lain',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
