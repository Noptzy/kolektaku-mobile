import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../src/rust/dto/media.dart';
import '../../src/rust/dto/sources.dart';
import '../../src/rust/dto/stream.dart';
import '../watch/episodes_sheet.dart';
import '../watch/player/standby_panel.dart';
import 'chapter_loader.dart';
import 'page_image.dart';
import 'page_heights.dart';
import 'read_failure.dart';
import 'read_progress.dart';
import 'read_request.dart';
import 'reader_controller.dart';
import 'reader_layers.dart';
import 'reader_pages.dart';
import 'reader_zoom.dart';

const _probeDepth = 0.3;

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({
    super.key,
    required this.request,
    this.loader,
    this.progress = const CoreReadProgress(),
    this.imageFor = networkPageImage,
    this.saveDelay = const Duration(seconds: 1),
  });

  final ReadRequest request;
  final ChapterLoader? loader;
  final ReadProgress progress;
  final PageImageFactory imageFor;
  final Duration saveDelay;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late final ReaderController _controller = ReaderController(
    request: widget.request,
    loader: widget.loader ?? ChapterLoader(),
    progress: widget.progress,
    saveDelay: widget.saveDelay,
  );
  ScrollController _scroll = ScrollController();
  PageHeights _metrics = PageHeights();
  final ReaderZoom _zoom = ReaderZoom();
  double _appliedZoom = 1;
  ChapterViewDto? _shown;
  bool _bars = true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChange);
    _zoom.addListener(_onZoom);
    _controller.load();
  }

  double get _width => _zoom.widthOf(MediaQuery.sizeOf(context).width);

  void _onZoom() {
    if (_zoom.zoom == _appliedZoom) return;
    if (_scroll.hasClients) {
      _scroll.jumpTo(_scroll.position.pixels * _zoom.zoom / _appliedZoom);
    }
    _appliedZoom = _zoom.zoom;
  }

  void _onChange() {
    final view = _controller.view;
    if (view == null || identical(view, _shown) || !mounted) return;
    _shown = view;
    _metrics = PageHeights();
    _scroll.dispose();
    _scroll = ScrollController(
      initialScrollOffset: _metrics.offsetOf(_controller.startPage, _width),
    );
    _bars = true;
    if (view.switchedFrom != null) {
      ShadToaster.of(context)
          .show(const ShadToast(description: Text('Dibaca dari sumber lain.')));
    }
  }

  void _onAspect(int index, double aspect) {
    final before = _metrics.heightOf(index, _width);
    if (!_metrics.record(index, aspect)) return;
    final shift = _metrics.heightOf(index, _width) - before;
    if (index < _controller.page && _scroll.hasClients) {
      _scroll.jumpTo(_scroll.position.pixels + shift);
    }
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification is UserScrollNotification &&
        notification.direction != ScrollDirection.idle &&
        _bars) {
      setState(() => _bars = false);
    }
    if (notification is ScrollUpdateNotification ||
        notification is ScrollEndNotification) {
      final metrics = notification.metrics;
      final probe = metrics.pixels + metrics.viewportDimension * _probeDepth;
      _controller.onPage(_metrics.indexAt(probe, _width, _controller.total));
    }
    return false;
  }

  void _showChapters() {
    showEpisodesSheet(
      context,
      units: _controller.units,
      current: _controller.current,
      kind: MediaKindDto.manga,
      infos: const {},
      onPick: _controller.goTo,
    );
  }

  void _go(UnitDto? target) {
    if (target != null) _controller.goTo(target);
  }

  String _title() =>
      '${widget.request.title}  ·  ${episodeTag(MediaKindDto.manga, _controller.current)}';

  void _back() => Navigator.of(context).maybePop();

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    _zoom.removeListener(_onZoom);
    _zoom.dispose();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF000000),
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) => _body(),
      ),
    );
  }

  Widget _body() {
    final view = _controller.view;
    if (_controller.error != null || view == null) {
      final failed = _controller.error != null;
      return StandbyPanel(
        title: _title(),
        imageUrl: widget.request.coverUrl,
        onBack: _back,
        message: failed ? 'Chapter tidak bisa dibuka' : 'Menyiapkan chapter…',
        detail: failed ? readFailureMessage(_controller.error) : null,
        onRetry: failed ? _controller.load : null,
      );
    }
    return ReaderLayers(
      title: _title(),
      barsVisible: _bars,
      page: _controller.page,
      total: _controller.total,
      onBack: _back,
      onChapters: _controller.units.isEmpty ? null : _showChapters,
      onPrevious: _controller.previous == null
          ? null
          : () => _go(_controller.previous),
      onNext: _controller.next == null ? null : () => _go(_controller.next),
      pages: ZoomSurface(
        model: _zoom,
        builder: (context, width) => ReaderPages(
          view: view,
          scroll: _scroll,
          metrics: _metrics,
          imageFor: widget.imageFor,
          next: _controller.next,
          onAspect: _onAspect,
          onNext: () => _go(_controller.next),
          onTap: () => setState(() => _bars = !_bars),
          onScroll: _onScroll,
          decodeScale: _zoom.decodeScale,
          physics: _zoom.pinching ? const NeverScrollableScrollPhysics() : null,
        ),
      ),
    );
  }
}
