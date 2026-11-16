import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'center_play_button.dart';
import 'clock_format.dart';
import 'playback_engine.dart';
import 'player_session.dart';
import 'player_settings_button.dart';
import 'seek_bar.dart';
import 'player_settings.dart';

class PlayerControls extends StatelessWidget {
  const PlayerControls({
    super.key,
    required this.session,
    required this.title,
    this.episodeLine,
    required this.fullscreen,
    required this.onFullscreen,
    required this.onBack,
    required this.onInteract,
    this.onEpisodes,
    this.audioPage,
    this.audioLabel,
  });

  final PlayerSession session;
  final String title;
  final String? episodeLine;
  final bool fullscreen;
  final VoidCallback onFullscreen;
  final VoidCallback onBack;
  final VoidCallback onInteract;
  final VoidCallback? onEpisodes;
  final SettingPage? audioPage;
  final String? audioLabel;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xB3000000),
                  Color(0x00000000),
                  Color(0xB3000000),
                ],
                stops: [0, 0.5, 1],
              ),
            ),
          ),
        ),
        CenterPlayButton(
          snapshot: session.engine.snapshot,
          onPressed: () {
            session.togglePlay();
            onInteract();
          },
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              _topBar(context),
              const Spacer(),
              SeekBar(
                snapshot: session.engine.snapshot,
                skips: session.extras.marks,
                onScrub: onInteract,
                onSeek: (fraction) {
                  session.seekToFraction(fraction);
                  onInteract();
                },
              ),
              _bottomBar(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _topBar(BuildContext context) {
    return Row(
      children: [
        ShadIconButton.ghost(
          key: const Key('back'),
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: onBack,
        ),
        Expanded(child: _heading(context)),
        if (onEpisodes != null)
          ShadIconButton.ghost(
            key: const Key('episodes'),
            icon: const Icon(LucideIcons.listVideo),
            onPressed: () {
              onEpisodes!();
              onInteract();
            },
          ),
      ],
    );
  }

  Widget _heading(BuildContext context) {
    final line = episodeLine;
    final muted = ShadTheme.of(context).colorScheme.mutedForeground;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        if (line != null)
          Text(
            line,
            key: const Key('episode-line'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: muted),
          ),
      ],
    );
  }

  Widget _bottomBar(BuildContext context) {
    return ValueListenableBuilder<PlaybackSnapshot>(
      valueListenable: session.engine.snapshot,
      builder: (context, snapshot, child) => Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    '${formatClock(snapshot.position)} / ${formatClock(snapshot.duration)}',
                    maxLines: 1,
                  ),
                ),
              ),
            ),
          ),
          PlayerSettingsButton(
            session: session,
            onInteract: onInteract,
            audioPage: audioPage,
            audioLabel: audioLabel,
          ),
          ShadIconButton.ghost(
            key: const Key('fullscreen'),
            icon: Icon(
              fullscreen ? LucideIcons.minimize : LucideIcons.maximize,
            ),
            onPressed: onFullscreen,
          ),
        ],
      ),
    );
  }
}
