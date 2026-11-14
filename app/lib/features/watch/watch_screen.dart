import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../data/providers/settings_providers.dart';
import '../../platform/pip.dart';
import '../../platform/screen_awake.dart';
import '../../src/rust/dto/settings.dart';
import '../detail/episode_info_map.dart';
import 'awake_guard.dart';
import 'controls_visibility.dart';
import 'episode_loader.dart';
import 'episodes_sheet.dart';
import 'player/fullscreen_mode.dart';
import 'player/playback_engine.dart';
import 'player/player_extras.dart';
import 'player/video_player_engine.dart';
import 'watch_controller.dart';
import 'watch_details.dart';
import 'watch_progress.dart';
import 'watch_request.dart';
import 'watch_stage.dart';

class WatchScreen extends StatefulWidget {
  const WatchScreen({
    super.key,
    required this.request,
    this.loader,
    this.engineFactory = VideoPlayerEngine.new,
    this.progress = const CoreWatchProgress(),
    this.fullscreen = const SystemFullscreenMode(),
    this.pip,
    this.awake,
    this.autoNextDelay = const Duration(seconds: 5),
    this.episodeInfos = const {},
    this.episodeArt,
    this.settings = defaultSettings,
    this.cueLoader,
    this.sourceNames = const {},
    this.sourceSummaries = const {},
    this.linkedSources = const [],
  });

  final WatchRequest request;
  final EpisodeLoader? loader;
  final PlaybackEngine Function() engineFactory;
  final WatchProgress progress;
  final FullscreenMode fullscreen;
  final PipHost? pip;
  final ScreenAwake? awake;
  final Duration autoNextDelay;
  final EpisodeInfos episodeInfos;
  final String? episodeArt;
  final SettingsDto settings;
  final CueLoader? cueLoader;
  final Map<String, String> sourceNames;
  final Map<String, String> sourceSummaries;
  final List<String> linkedSources;

  @override
  State<WatchScreen> createState() => _WatchScreenState();
}

class _WatchScreenState extends State<WatchScreen> {
  late final PipHost _pipHost = widget.pip ?? ChannelPipHost();
  late final AwakeGuard _awakeGuard = AwakeGuard(
    widget.awake ?? ChannelScreenAwake(),
  );
  late final WatchController _controller = WatchController(
    request: widget.request,
    loader: widget.loader ?? EpisodeLoader(),
    engineFactory: widget.engineFactory,
    progress: widget.progress,
    pip: _pipHost,
    autoNextDelay: widget.autoNextDelay,
    settings: widget.settings,
    cueLoader: widget.cueLoader,
  );
  late final ControlsVisibility _controls = ControlsVisibility(
    isPlaying: () =>
        _controller.session?.engine.snapshot.value.playing ?? false,
  );
  bool _fullscreen = false;
  LoadedEpisode? _announced;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChange);
    _controller.load();
  }

  void _onChange() {
    _awakeGuard.follow(_controller.session?.engine.snapshot);
    final loaded = _controller.loaded;
    if (loaded == null || identical(loaded, _announced)) return;
    _announced = loaded;
    _controls.schedule();
    if (loaded.switchedFrom != null && mounted) {
      ShadToaster.of(
        context,
      ).show(const ShadToast(description: Text('Diputar dari sumber lain.')));
    }
  }

  void _goBack() {
    if (_fullscreen) {
      _setFullscreen(false);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _showEpisodes() {
    showEpisodesSheet(
      context,
      units: _controller.units,
      current: _controller.current,
      kind: widget.request.kind,
      infos: widget.episodeInfos,
      art: widget.episodeArt ?? widget.request.coverUrl,
      onPick: _controller.goTo,
    );
  }

  Future<void> _setFullscreen(bool on) async {
    setState(() => _fullscreen = on);
    await (on ? widget.fullscreen.enter() : widget.fullscreen.exit());
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    _awakeGuard.dispose();
    _controller.dispose();
    _controls.dispose();
    if (widget.pip == null) _pipHost.dispose();
    if (_fullscreen) widget.fullscreen.exit();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_fullscreen,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _setFullscreen(false);
      },
      child: ColoredBox(
        color: const Color(0xFF000000),
        child: ListenableBuilder(
          listenable: Listenable.merge([_controller, _controls]),
          builder: (context, child) => _fullscreen || _controller.inPip
              ? _stage()
              : SafeArea(
                  child: Column(
                    children: [
                      AspectRatio(aspectRatio: 16 / 9, child: _stage()),
                      Expanded(
                        child: WatchDetails(
                          controller: _controller,
                          infos: widget.episodeInfos,
                          art: widget.episodeArt ?? widget.request.coverUrl,
                          sourceNames: widget.sourceNames,
                          sourceSummaries: widget.sourceSummaries,
                          linkedSources: widget.linkedSources,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _stage() {
    return WatchStage(
      controller: _controller,
      controls: _controls,
      request: widget.request,
      infos: widget.episodeInfos,
      settings: widget.settings,
      fullscreen: _fullscreen,
      onFullscreen: () => _setFullscreen(!_fullscreen),
      onBack: _goBack,
      onEpisodes: _showEpisodes,
    );
  }
}
