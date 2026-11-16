import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import 'player/playback_engine.dart';
import 'watch_controller.dart';

const _shortestFilmMinutes = 40;
const _enoughOfTheFilm = 0.6;

bool looksTooShort({required Duration length, required int? expectedMinutes}) {
  final expected = expectedMinutes;
  if (expected == null || expected < _shortestFilmMinutes) return false;
  if (length == Duration.zero) return false;
  return length.inSeconds < expected * 60 * _enoughOfTheFilm;
}

class ShortFilmGuard extends StatelessWidget {
  const ShortFilmGuard({super.key, required this.controller});

  final WatchController controller;

  @override
  Widget build(BuildContext context) {
    final session = controller.session;
    final expected = controller.request.expectedMinutes;
    if (session == null || expected == null) return const SizedBox.shrink();
    return ValueListenableBuilder<PlaybackSnapshot>(
      valueListenable: session.engine.snapshot,
      builder: (context, snapshot, _) {
        final short = looksTooShort(
          length: snapshot.duration,
          expectedMinutes: expected,
        );
        if (!short) return const SizedBox.shrink();
        return ShortFilmNotice(onTryOther: controller.tryOtherSource);
      },
    );
  }
}

class ShortFilmNotice extends StatelessWidget {
  const ShortFilmNotice({super.key, required this.onTryOther});

  final VoidCallback onTryOther;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.sm),
      child: Column(
        key: const Key('short-film-notice'),
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Spacing.sm,
        children: [
          Text(
            'Video ini mungkin bukan filmnya',
            style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            'Durasinya jauh lebih pendek daripada film aslinya. Bisa jadi '
            'rekaman bioskop atau potongan.',
            style: theme.textTheme.muted,
          ),
          ShadButton.outline(
            key: const Key('short-film-try-other'),
            size: ShadButtonSize.sm,
            onPressed: onTryOther,
            child: const Text('Coba sumber lain'),
          ),
        ],
      ),
    );
  }
}
