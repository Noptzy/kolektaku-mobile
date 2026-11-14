import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/sources.dart';
import 'episode_loader.dart';
import 'watch_heading.dart';

class WatchInfo extends StatelessWidget {
  const WatchInfo({
    super.key,
    required this.loaded,
    required this.title,
    required this.episodeLine,
    this.synopsis,
    this.playing,
    this.previous,
    this.next,
    this.onPrevious,
    this.onNext,
    this.onChangeServer,
  });

  final LoadedEpisode? loaded;
  final String title;
  final String episodeLine;
  final String? synopsis;
  final String? playing;
  final UnitDto? previous;
  final UnitDto? next;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onChangeServer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Spacing.sm,
        children: [
          if (loaded?.switchedFrom != null)
            const ShadAlert(
              key: Key('switched-notice'),
              title: Text('Diputar dari sumber lain'),
              description: Text('Sumber sebelumnya sedang bermasalah.'),
            ),
          WatchHeading(
            title: title,
            episodeLine: episodeLine,
            synopsis: synopsis,
            playing: playing,
          ),
          ..._controls(),
        ],
      ),
    );
  }

  List<Widget> _controls() {
    return [
      Row(
        spacing: Spacing.sm,
        children: [
          Expanded(
            child: _NavButton(
              key: const Key('previous-episode'),
              label: 'Sebelum',
              icon: LucideIcons.skipBack,
              onPressed: previous == null ? null : onPrevious,
            ),
          ),
          Expanded(
            child: _NavButton(
              key: const Key('change-server'),
              label: 'Server',
              icon: LucideIcons.server,
              onPressed: loaded == null ? null : onChangeServer,
            ),
          ),
          Expanded(
            child: _NavButton(
              key: const Key('next-episode'),
              label: 'Berikutnya',
              icon: LucideIcons.skipForward,
              onPressed: next == null ? null : onNext,
              iconAfter: true,
            ),
          ),
        ],
      ),
    ];
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.iconAfter = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool iconAfter;

  @override
  Widget build(BuildContext context) {
    final glyph = Icon(icon, size: 16);
    return ShadButton.outline(
      onPressed: onPressed,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
      gap: Spacing.xs,
      leading: iconAfter ? null : glyph,
      trailing: iconAfter ? glyph : null,
      child: Flexible(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label, maxLines: 1),
        ),
      ),
    );
  }
}
