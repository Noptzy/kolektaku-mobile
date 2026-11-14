import 'package:flutter/widgets.dart';

import '../../src/rust/dto/settings.dart';
import '../detail/episode_info_map.dart';
import 'auto_next_banner.dart';
import 'controls_visibility.dart';
import 'player/standby_panel.dart';
import 'player/watch_player_view.dart';
import 'server_flow.dart';
import 'watch_controller.dart';
import 'watch_failure.dart';
import 'watch_labels.dart';
import 'watch_request.dart';
import 'player/player_settings.dart';

class WatchStage extends StatelessWidget {
  const WatchStage({
    super.key,
    required this.controller,
    required this.controls,
    required this.request,
    required this.infos,
    required this.settings,
    required this.fullscreen,
    required this.onFullscreen,
    required this.onBack,
    required this.onEpisodes,
    this.audioPage,
  });

  final WatchController controller;
  final ControlsVisibility controls;
  final WatchRequest request;
  final EpisodeInfos infos;
  final SettingsDto settings;
  final bool fullscreen;
  final VoidCallback onFullscreen;
  final VoidCallback onBack;
  final VoidCallback onEpisodes;
  final SettingPage? audioPage;

  Widget _standby(String message, {String? detail, VoidCallback? onRetry}) {
    return StandbyPanel(
      title: watchTitle(request, controller.current),
      imageUrl: watchBackdrop(request, infos, controller.current),
      onBack: onBack,
      message: message,
      detail: detail,
      onRetry: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = controller.session;
    if (controller.error != null) {
      return _standby(
        'Episode tidak bisa dibuka',
        detail: watchFailureMessage(controller.error),
        onRetry: controller.load,
      );
    }
    if (session == null) return _standby('Menyiapkan video…');
    return Stack(
      fit: StackFit.expand,
      children: [
        WatchPlayerView(
          session: session,
          title: request.title,
          episodeLine: watchEpisodeLine(request, infos, controller.current),
          onEpisodes: controller.units.isEmpty || !fullscreen
              ? null
              : onEpisodes,
          fullscreen: fullscreen,
          showChrome: !controller.inPip,
          controlsVisible: controls.visible,
          onToggleControls: controls.toggle,
          onInteract: controls.interacted,
          onFullscreen: onFullscreen,
          onBack: onBack,
          audioPage: audioPage,
          audioLabel: currentAudioLabel(controller),
          settings: settings,
        ),
        if (controller.next != null && !controller.inPip)
          AutoNextBanner(
            autoNext: controller.autoNext,
            label: 'Episode berikutnya',
          ),
      ],
    );
  }
}
