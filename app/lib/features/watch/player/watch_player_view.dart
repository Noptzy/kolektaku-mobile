import 'package:flutter/widgets.dart';

import '../../../data/providers/settings_providers.dart';
import '../../../src/rust/dto/settings.dart';

import 'double_tap_zones.dart';
import 'playback_engine.dart';
import 'player_controls.dart';
import 'player_overlays.dart';
import 'player_session.dart';
import 'skip_button.dart';
import 'subtitle_overlay.dart';
import 'translation_notice.dart';
import 'player_settings.dart';

class WatchPlayerView extends StatelessWidget {
  const WatchPlayerView({
    super.key,
    required this.session,
    required this.title,
    this.episodeLine,
    required this.fullscreen,
    required this.controlsVisible,
    required this.onToggleControls,
    required this.onInteract,
    required this.onFullscreen,
    required this.onBack,
    this.onEpisodes,
    this.audioPage,
    this.audioLabel,
    this.showChrome = true,
    this.settings = defaultSettings,
  });

  final PlayerSession session;
  final String title;
  final String? episodeLine;
  final bool fullscreen;
  final bool controlsVisible;
  final VoidCallback onToggleControls;
  final VoidCallback onInteract;
  final VoidCallback onFullscreen;
  final VoidCallback onBack;
  final VoidCallback? onEpisodes;
  final SettingPage? audioPage;
  final String? audioLabel;
  final bool showChrome;
  final SettingsDto settings;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF000000)),
        session.engine.view,
        SubtitleOverlay(
          session: session,
          settings: settings,
          lifted: controlsVisible && showChrome,
        ),
        TranslationNotice(session: session),
        if (showChrome) ..._chrome(),
        if (showChrome) SkipButton(session: session, lifted: controlsVisible),
        _failure(),
      ],
    );
  }

  List<Widget> _chrome() {
    return [
      DoubleTapZones(
        step: session.skipStep,
        onTap: onToggleControls,
        onSkip: (delta) {
          session.skip(delta);
          onInteract();
        },
      ),
      _buffering(),
      AnimatedOpacity(
        key: const Key('controls-fade'),
        opacity: controlsVisible ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: IgnorePointer(
          ignoring: !controlsVisible,
          child: PlayerControls(
            session: session,
            title: title,
            episodeLine: episodeLine,
            fullscreen: fullscreen,
            onFullscreen: onFullscreen,
            onBack: onBack,
            onInteract: onInteract,
            onEpisodes: onEpisodes,
            audioPage: audioPage,
            audioLabel: audioLabel,
          ),
        ),
      ),
    ];
  }

  Widget _buffering() {
    return ValueListenableBuilder<PlaybackSnapshot>(
      valueListenable: session.engine.snapshot,
      builder: (context, snapshot, child) =>
          snapshot.buffering ? const BufferingBadge() : const SizedBox.shrink(),
    );
  }

  Widget _failure() {
    return ValueListenableBuilder<String?>(
      valueListenable: session.failure,
      builder: (context, reason, child) => reason == null
          ? const SizedBox.shrink()
          : StatusPanel(
              message: 'Video gagal diputar',
              detail: reason,
              onRetry: session.retry,
            ),
    );
  }
}
