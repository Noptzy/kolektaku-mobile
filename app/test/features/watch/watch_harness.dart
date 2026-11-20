import 'dart:async';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/theme/kolektaku_theme.dart';
import 'package:kolektaku/platform/pip.dart';
import 'package:kolektaku/platform/screen_awake.dart';
import 'package:kolektaku/features/detail/episode_info_map.dart';
import 'package:kolektaku/features/watch/episode_loader.dart';
import 'package:kolektaku/features/watch/player/fullscreen_mode.dart';
import 'package:kolektaku/features/watch/watch_progress.dart';
import 'package:kolektaku/features/watch/watch_request.dart';
import 'package:kolektaku/features/watch/watch_screen.dart';
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:kolektaku/src/rust/dto/sources.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/fake_download_gateway.dart';
import 'fake_engine.dart';
import 'watch_fixtures.dart';

class FakeProgress implements WatchProgress {
  FakeProgress({this.resume});

  Duration? resume;
  final List<(Duration, Duration)> saved = [];

  @override
  Future<Duration?> resumeAt(WatchRequest request) async => resume;

  @override
  Future<void> save(
    WatchRequest request,
    Duration position,
    Duration length,
  ) async => saved.add((position, length));
}

class FakeFullscreen implements FullscreenMode {
  final List<String> log = [];

  @override
  Future<void> enter() async => log.add('enter');

  @override
  Future<void> exit() async => log.add('exit');
}

class FakeAwake implements ScreenAwake {
  final List<bool> calls = [];

  bool get on => calls.isNotEmpty && calls.last;

  @override
  Future<void> keepOn(bool on) async => calls.add(on);
}

class FakePip implements PipHost {
  final List<String> log = [];
  final StreamController<bool> modes = StreamController<bool>.broadcast();
  final StreamController<void> toggles = StreamController<void>.broadcast();

  @override
  Stream<bool> get modeChanges => modes.stream;

  @override
  Stream<void> get toggleRequests => toggles.stream;

  @override
  Future<void> arm({
    required bool playing,
    int width = 16,
    int height = 9,
  }) async => log.add('arm $playing');

  @override
  Future<void> update({required bool playing}) async =>
      log.add('update $playing');

  @override
  Future<void> disarm() async => log.add('disarm');

  @override
  Future<void> dispose() async {}
}

class WatchHarness {
  WatchHarness({
    this.resume,
    this.startAt,
    this.sourceSwitched,
    this.failToLoad = false,
    this.unitCount = 12,
    this.episode = 1,
    this.autoNextDelay = const Duration(seconds: 5),
    this.scene,
    this.hold,
    this.infos = const {},
    this.variants = false,
    this.linked = const [],
  });

  final Completer<void>? hold;
  final EpisodeInfos infos;
  final Duration? resume;
  final Duration? startAt;
  final String? sourceSwitched;
  final bool failToLoad;
  final int unitCount;
  final bool variants;
  final List<String> linked;
  final List<String?> preferredAsked = [];
  final double episode;
  final Duration autoNextDelay;
  final SceneEstimate? scene;
  final List<double> openedEpisodes = [];
  final List<List<String>> excluded = [];
  final List<String> resolvedServers = [];
  final FakeEngine engine = FakeEngine();
  final FakeFullscreen fullscreen = FakeFullscreen();
  final FakePip pip = FakePip();
  final FakeAwake awake = FakeAwake();
  late final FakeProgress progress = FakeProgress(resume: resume);
  int loads = 0;
  int resolves = 0;

  EpisodeLoader get loader => EpisodeLoader(
    open:
        ({
          required MediaRefDto reference,
          required double episode,
          String? preferred,
          required List<String> exclude,
          String? audio,
        }) async {
          loads++;
          await hold?.future;
          openedEpisodes.add(episode);
          preferredAsked.add(preferred);
          excluded.add(List.of(exclude));
          if (failToLoad && loads == 1) throw StateError('no source');
          return playbackOn(
            preferred ?? (exclude.isEmpty ? 'a' : 'b'),
            episode: episode,
            switchedFrom: exclude.isEmpty ? sourceSwitched : null,
            servers: variants ? 4 : 2,
            variants: variants,
          );
        },
    resolve:
        ({
          required String source,
          required String episodeId,
          required String server,
        }) async {
          resolves++;
          resolvedServers.add(server);
          return streamOf(resolves > 1 ? 'fresh' : 'first');
        },
    units: ({required MediaRefDto reference, String? source}) async => UnitsDto(
      source: source ?? 'a',
      item: 'a-item',
      units: [
        for (var i = 1; i <= unitCount; i++)
          UnitDto(id: 'u$i', number: i.toDouble(), label: 'Episode $i'),
      ],
    ),
  );

  final FakeDownloadGateway downloads = FakeDownloadGateway();

  Widget app() => withDownloadFakes(_shad(), downloads);

  Widget _shad() {
    return ShadApp(
      darkTheme: kolektakuDarkTheme(),
      themeMode: ThemeMode.dark,
      home: WatchScreen(
        request: WatchRequest(
          reference: reference,
          kind: MediaKindDto.anime,
          title: 'Kimi no Na wa.',
          episode: episode,
          startAt: startAt,
          scene: scene,
        ),
        loader: loader,
        engineFactory: () => engine,
        progress: progress,
        fullscreen: fullscreen,
        pip: pip,
        awake: awake,
        autoNextDelay: autoNextDelay,
        episodeInfos: infos,
        sourceNames: const {'a': 'Sumber anime 1', 'b': 'Sumber anime 2'},
        sourceSummaries: const {
          'a': 'Subtitle Indonesia selalu tersedia.',
          'b': 'Kebanyakan subtitle Inggris.',
        },
        linkedSources: linked,
      ),
    );
  }

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }
}
