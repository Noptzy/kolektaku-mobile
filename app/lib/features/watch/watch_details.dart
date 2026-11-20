import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/sources.dart';
import '../detail/episode_info_map.dart';
import '../detail/episode_row.dart';
import '../detail/episode_window.dart';
import '../downloads/download_playing_button.dart';
import 'scene_estimate_bar.dart';
import 'watch_scroll.dart';
import 'watch_section_heading.dart';
import 'server_flow.dart';
import 'watch_controller.dart';
import 'watch_info.dart';
import 'short_film_notice.dart';
import 'watch_labels.dart';

export 'watch_scroll.dart';

class WatchDetails extends StatefulWidget {
  const WatchDetails({
    super.key,
    required this.controller,
    this.infos = const {},
    this.art,
    this.sourceNames = const {},
    this.sourceSummaries = const {},
    this.linkedSources = const [],
  });

  final WatchController controller;
  final EpisodeInfos infos;
  final String? art;
  final Map<String, String> sourceNames;
  final Map<String, String> sourceSummaries;
  final List<String> linkedSources;

  @override
  State<WatchDetails> createState() => _WatchDetailsState();
}

class _WatchDetailsState extends State<WatchDetails> {
  final ScrollController _scroll = ScrollController();
  final GlobalKey _header = GlobalKey();
  double? _followed;
  int _followedCount = 0;

  WatchController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_follow);
    WidgetsBinding.instance.addPostFrameCallback((_) => _follow());
  }

  @override
  void dispose() {
    _controller.removeListener(_follow);
    _scroll.dispose();
    super.dispose();
  }

  void _follow() {
    final units = _controller.units;
    if (units.isEmpty) return;
    final current = _controller.current;
    if (current == _followed && units.length == _followedCount) return;
    final first = _followed == null;
    _followed = current;
    _followedCount = units.length;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTo(first));
  }

  void _scrollTo(bool instant) {
    if (!mounted || !_scroll.hasClients) return;
    final sorted = sortedUnits(_controller.units, descending: false);
    final at = indexOfNumber(sorted, _controller.current);
    final box = _header.currentContext?.findRenderObject() as RenderBox?;
    if (at == null || box == null || !box.hasSize) return;
    final position = _scroll.position;
    final target = scrollTargetFor(
      headerHeight: box.size.height,
      index: at,
      offset: position.pixels,
      viewport: position.viewportDimension,
      maxExtent: position.maxScrollExtent,
    );
    if (target == null) return;
    if (instant) {
      _scroll.jumpTo(target);
    } else {
      _scroll.animateTo(
        target,
        duration: Motion.regular,
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _go(UnitDto? unit) {
    if (unit != null) _controller.goTo(unit);
  }

  Future<void> _changeServer() => changeServer(
    context,
    _controller,
    linkedSources: widget.linkedSources,
    sourceNames: widget.sourceNames,
    sourceSummaries: widget.sourceSummaries,
  );

  EpisodeRow _row(UnitDto unit, {bool playing = false}) {
    return EpisodeRow(
      art: widget.art,
      unit: unit,
      kind: _controller.request.kind,
      info: widget.infos[unit.number],
      nowPlaying: playing,
      onTap: () => _go(unit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sorted = sortedUnits(_controller.units, descending: false);
    final next = _controller.next;
    final theme = ShadTheme.of(context);
    return ColoredBox(
      color: theme.colorScheme.background,
      child: Column(
        children: [
          WatchInfo(
            loaded: _controller.loaded,
            title: _controller.request.title,
            episodeLine: watchEpisodeLine(
              _controller.request,
              widget.infos,
              _controller.current,
            ),
            synopsis: _controller.request.synopsis,
            playing: playingLabel(_controller.loaded, widget.sourceNames),
            previous: _controller.previous,
            next: next,
            onPrevious: () => _go(_controller.previous),
            onNext: () => _go(next),
            onChangeServer: _changeServer,
            downloadTarget: playingTarget(_controller.request),
          ),
          ShortFilmGuard(controller: _controller),
          Expanded(
            child: CustomScrollView(
              controller: _scroll,
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    key: _header,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_controller.request.scene != null &&
                          _controller.session != null)
                        SceneEstimateBar(
                          session: _controller.session!,
                          estimate: _controller.request.scene!,
                          onOthers: () => Navigator.of(context).maybePop(),
                        ),
                      if (next != null) ...[
                        const WatchSectionHeading(text: 'Selanjutnya'),
                        _row(next),
                      ],
                      if (sorted.isNotEmpty)
                        const WatchSectionHeading(text: 'Semua episode'),
                    ],
                  ),
                ),
                SliverFixedExtentList(
                  itemExtent: episodeRowHeight,
                  delegate: SliverChildBuilderDelegate(
                    childCount: sorted.length,
                    (context, index) {
                      final unit = sorted[index];
                      return _row(
                        unit,
                        playing: unit.number == _controller.current,
                      );
                    },
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: Spacing.xl)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
