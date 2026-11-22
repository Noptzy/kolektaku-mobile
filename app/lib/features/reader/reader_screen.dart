import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/widgets.dart';

import '../../src/rust/dto/sources.dart';
import '../../src/rust/dto/stream.dart';
import 'chapter_loader.dart';
import 'page_image.dart';
import 'read_progress.dart';
import 'read_request.dart';
import 'reader_actions.dart';
import 'reader_controller.dart';
import 'reader_divider.dart';
import 'reader_layers.dart';
import 'reader_notices.dart';
import 'reader_pages.dart';
import 'reader_standby.dart';
import 'reader_zoom.dart';
import 'scroll_anchor.dart';
import 'stack_metrics.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({
    super.key,
    required this.request,
    this.loader,
    this.progress = const CoreReadProgress(),
    this.imageFor = networkPageImage,
    this.saveDelay = const Duration(seconds: 1),
    this.autoContinue = true,
  });

  final bool autoContinue;
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
    autoContinue: widget.autoContinue,
  );
  ScrollController _scroll = ScrollController();
  final StackMetrics _metrics = StackMetrics();
  final ReaderZoom _zoom = ReaderZoom();
  late final ScrollAnchor _anchor = ScrollAnchor(metrics: _metrics);
  ChapterViewDto? _shown;
  int _known = 0;
  bool _bars = true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChange);
    _zoom.addListener(_onZoom);
    _controller.load();
  }

  double get _width => _zoom.widthOf(MediaQuery.sizeOf(context).width);

  void _onZoom() =>
      _anchor.followZoom(_scroll, _zoom.zoom, focalY: _zoom.focalY);

  void _onChange() {
    final chapters = _controller.chapters;
    if (chapters.isEmpty || !mounted) return;
    final first = chapters.first;
    if (identical(first, _shown)) {
      while (_known < chapters.length) {
        _metrics.append(chapters[_known++].pages.length);
      }
      return;
    }
    _shown = first;
    _metrics.reset(first.pages.length);
    _known = 1;
    _scroll.dispose();
    _scroll = ScrollController(
      initialScrollOffset: _metrics.offsetOf(0, _controller.startPage, _width),
    );
    _bars = true;
    announceReaderStart(
      context,
      switchedFrom: first.switchedFrom,
      startPage: _controller.startPage,
    );
  }

  void _onAspect(int chapter, int index, double aspect) {
    _anchor.keepPlace(
      scroll: _scroll,
      width: _width,
      chapter: chapter,
      index: index,
      aspect: aspect,
      above:
          chapter < _controller.visible ||
          (chapter == _controller.visible && index < _controller.page),
    );
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification is UserScrollNotification &&
        notification.direction != ScrollDirection.idle &&
        _bars) {
      setState(() => _bars = false);
    }
    if (notification is ScrollUpdateNotification ||
        notification is ScrollEndNotification) {
      final spot = _metrics.spotAt(notification.metrics, _width);
      _controller.onSpot(spot.chapter, spot.page);
    }
    return false;
  }

  void _go(UnitDto? target) {
    if (target != null) _controller.goTo(target);
  }

  String _title() => readerTitle(widget.request, _controller.current);

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
      return readerStandby(
        title: _title(),
        coverUrl: widget.request.coverUrl,
        onBack: _back,
        error: _controller.error,
        onRetry: _controller.load,
      );
    }
    return ReaderLayers(
      title: _title(),
      barsVisible: _bars,
      page: _controller.page,
      total: _controller.total,
      onBack: _back,
      onChapters: _controller.units.isEmpty
          ? null
          : () => showReaderChapters(context, _controller),
      onPrevious: _controller.previous == null
          ? null
          : () => _go(_controller.previous),
      onNext: _controller.next == null ? null : () => _go(_controller.next),
      pages: ZoomSurface(
        model: _zoom,
        builder: (context, width) => ReaderPages(
          chapters: _controller.chapters,
          scroll: _scroll,
          metrics: _metrics,
          imageFor: widget.imageFor,
          dividerAt: (chapter) => readerDivider(_controller, chapter),
          onAspect: _onAspect,
          onTap: () => setState(() => _bars = !_bars),
          onScroll: _onScroll,
          decodeScale: _zoom.decodeScale,
          physics: _zoom.pinching ? const NeverScrollableScrollPhysics() : null,
        ),
      ),
    );
  }
}
