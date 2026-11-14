import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/pesan_error.dart';
import '../../src/rust/dto/media.dart';
import '../../src/rust/dto/stream.dart';
import '../../src/rust/error.dart';
import '../watch/episodes_sheet.dart';
import '../watch/player/standby_panel.dart';
import 'chapter_loader.dart';
import 'page_image.dart';
import 'page_heights.dart';
import 'read_progress.dart';
import 'read_request.dart';
import 'reader_bars.dart';
import 'reader_controller.dart';
import 'reader_pages.dart';

const _probeDepth = 0.3;

String readFailureMessage(Object? error) {
  if (error is BridgeError) return pesanError(error);
  return 'Terjadi masalah saat membuka chapter. Coba lagi.';
}

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
  ChapterViewDto? _shown;
  bool _bars = true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChange);
    _controller.load();
  }

  double get _width => MediaQuery.sizeOf(context).width;

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

  void _goNext() {
    final target = _controller.next;
    if (target != null) _controller.goTo(target);
  }

  void _goPrevious() {
    final target = _controller.previous;
    if (target != null) _controller.goTo(target);
  }

  String _title() =>
      '${widget.request.title}  ·  ${episodeTag(MediaKindDto.manga, _controller.current)}';

  void _back() => Navigator.of(context).maybePop();

  @override
  void dispose() {
    _controller.removeListener(_onChange);
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
    return Stack(
      fit: StackFit.expand,
      children: [
        ReaderPages(
          view: view,
          scroll: _scroll,
          metrics: _metrics,
          imageFor: widget.imageFor,
          next: _controller.next,
          onAspect: _onAspect,
          onNext: _goNext,
          onTap: () => setState(() => _bars = !_bars),
          onScroll: _onScroll,
        ),
        _bar(
          top: true,
          child: ReaderTopBar(
            title: _title(),
            onBack: _back,
            onChapters: _controller.units.isEmpty ? null : _showChapters,
          ),
        ),
        _bar(
          top: false,
          child: ReaderBottomBar(
            page: _controller.page,
            total: _controller.total,
            onPrevious: _controller.previous == null ? null : _goPrevious,
            onNext: _controller.next == null ? null : _goNext,
          ),
        ),
      ],
    );
  }

  Widget _bar({required bool top, required Widget child}) {
    return Positioned(
      top: top ? 0 : null,
      bottom: top ? null : 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: _bars ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: IgnorePointer(ignoring: !_bars, child: child),
      ),
    );
  }
}
