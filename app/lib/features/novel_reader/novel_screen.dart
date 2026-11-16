import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../data/providers/gateway_providers.dart';
import '../../src/rust/dto/media.dart';
import '../../src/rust/dto/novel.dart';
import '../../src/rust/dto/sources.dart';
import '../watch/episodes_sheet.dart';
import '../watch/player/standby_panel.dart';
import 'block_scroll.dart';
import 'highlight_actions.dart';
import 'highlight_book.dart';
import 'novel_blocks.dart';
import 'novel_controller.dart';
import 'novel_failure.dart';
import 'novel_loader.dart';
import 'novel_notices.dart';
import 'novel_progress.dart';
import 'novel_reading.dart';
import 'novel_request.dart';

class NovelScreen extends ConsumerStatefulWidget {
  const NovelScreen({
    super.key,
    required this.request,
    this.loader,
    this.progress = const CoreNovelProgress(),
    this.imageFor = networkIllustration,
    this.saveDelay = const Duration(seconds: 1),
    this.autoContinue = true,
  });

  final bool autoContinue;
  final NovelRequest request;
  final NovelLoader? loader;
  final NovelProgress progress;
  final NovelImageFactory imageFor;
  final Duration saveDelay;

  @override
  ConsumerState<NovelScreen> createState() => _NovelScreenState();
}

class _NovelScreenState extends ConsumerState<NovelScreen> {
  late final NovelController _controller = NovelController(
    request: widget.request,
    loader: widget.loader ?? NovelLoader(),
    progress: widget.progress,
    saveDelay: widget.saveDelay,
    autoContinue: widget.autoContinue,
  );
  late final HighlightBook _book = HighlightBook(
    gateway: ref.read(highlightGatewayProvider),
    reference: widget.request.reference,
  );
  late final HighlightActions _highlights = HighlightActions(
    book: _book,
    controller: _controller,
    request: widget.request,
  );
  final GlobalKey _listKey = GlobalKey();
  ScrollController _scroll = ScrollController();
  NovelChapterDto? _shown;
  bool _bars = true;
  bool _probing = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChange);
    _controller.load();
  }

  void _onChange() {
    _highlights.loadAll();
    final view = _controller.chapters.firstOrNull;
    if (view == null || identical(view, _shown) || !mounted) return;
    _shown = view;
    _scroll.dispose();
    _scroll = ScrollController();
    _bars = true;
    final start = _controller.startBlock;
    if (start > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        jumpToBlock(_scroll, () => _listKey.currentContext, start);
      });
    }
    announceChapter(context, view);
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification is UserScrollNotification &&
        notification.direction != ScrollDirection.idle &&
        _bars) {
      setState(() => _bars = false);
    }
    if (notification is ScrollUpdateNotification ||
        notification is ScrollEndNotification) {
      _probeAfterLayout();
    }
    return false;
  }

  void _probeAfterLayout() {
    if (_probing) return;
    _probing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _probing = false;
      if (!mounted) return;
      final index = firstVisibleBlock(_listKey.currentContext);
      if (index != null) _controller.onFlat(index);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _showChapters() {
    showEpisodesSheet(
      context,
      units: _controller.units,
      current: _controller.current,
      kind: MediaKindDto.novel,
      infos: const {},
      onPick: _controller.goTo,
    );
  }

  void _go(UnitDto? target) {
    if (target != null) _controller.goTo(target);
  }

  String _title() =>
      '${widget.request.title}  ·  ${episodeTag(MediaKindDto.novel, _controller.current)}';

  void _back() => Navigator.of(context).maybePop();

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    _controller.dispose();
    _book.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ShadTheme.of(context).colorScheme.background,
      child: ListenableBuilder(
        listenable: Listenable.merge([_controller, _book]),
        builder: (context, child) => _body(),
      ),
    );
  }

  Widget _body() {
    final view = _controller.view;
    if (_controller.error != null) {
      return NovelFailure(
        title: _title(),
        error: _controller.error,
        onBack: _back,
        onRetry: _controller.load,
        onOtherSource: _controller.tryOtherSource,
      );
    }
    if (view == null) {
      return StandbyPanel(
        title: _title(),
        imageUrl: widget.request.coverUrl,
        onBack: _back,
        message: 'Menyiapkan chapter…',
      );
    }
    return _reading();
  }

  Widget _reading() {
    return NovelReading(
      controller: _controller,
      highlights: _highlights,
      scroll: _scroll,
      listKey: _listKey,
      barsVisible: _bars,
      title: _title(),
      imageFor: widget.imageFor,
      onToggleBars: () => setState(() => _bars = !_bars),
      onScroll: _onScroll,
      onBack: _back,
      onChapters: _showChapters,
      onGo: _go,
    );
  }
}
