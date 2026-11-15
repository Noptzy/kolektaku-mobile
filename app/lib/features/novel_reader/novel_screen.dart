import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../data/providers/settings_providers.dart';
import '../../src/rust/dto/media.dart';
import '../../src/rust/dto/novel.dart';
import '../../src/rust/dto/sources.dart';
import '../reader/reader_bars.dart';
import '../watch/episodes_sheet.dart';
import '../watch/player/standby_panel.dart';
import 'block_scroll.dart';
import 'novel_bars.dart';
import 'novel_blocks.dart';
import 'novel_controller.dart';
import 'novel_failure.dart';
import 'novel_loader.dart';
import 'novel_progress.dart';
import 'novel_request.dart';
import 'reading_look_sheet.dart';

class NovelScreen extends ConsumerStatefulWidget {
  const NovelScreen({
    super.key,
    required this.request,
    this.loader,
    this.progress = const CoreNovelProgress(),
    this.imageFor = networkIllustration,
    this.saveDelay = const Duration(seconds: 1),
  });

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
    final view = _controller.view;
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
    _announce(view);
  }

  void _announce(NovelChapterDto view) {
    final toaster = ShadToaster.of(context);
    if (view.switchedFrom != null) {
      toaster.show(
        const ShadToast(description: Text('Dibaca dari sumber lain.')),
      );
    }
    if (view.translationFailed) {
      toaster.show(
        const ShadToast(
          description: Text(
            'Terjemahan belum bisa dimuat. Teks asli yang tampil.',
          ),
        ),
      );
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
      if (index != null) _controller.onBlock(index);
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
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ShadTheme.of(context).colorScheme.background,
      child: ListenableBuilder(
        listenable: _controller,
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
    final settings = ref.watch(currentSettingsProvider);
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: Stack(
        fit: StackFit.expand,
        children: [
          NovelBlockList(
            listKey: _listKey,
            scroll: _scroll,
            blocks: _controller.blocks,
            size: settings.readingSize,
            spacing: settings.readingSpacing,
            current: _controller.current,
            next: _controller.next,
            onNext: () => _go(_controller.next),
            onTap: () => setState(() => _bars = !_bars),
            imageFor: widget.imageFor,
          ),
          _bar(
            top: true,
            child: NovelTopBar(
              title: _title(),
              caption: _caption(),
              onBack: _back,
              onLook: () => showReadingLookSheet(context),
              onChapters: _controller.units.isEmpty ? null : _showChapters,
              onToggleOriginal: _controller.hasTranslation
                  ? _controller.toggleOriginal
                  : null,
              showingOriginal: _controller.showOriginal,
            ),
          ),
          _bar(
            top: false,
            child: ReaderBottomBar(
              page: _controller.block,
              total: _controller.total,
              onPrevious: _controller.previous == null
                  ? null
                  : () => _go(_controller.previous),
              onNext: _controller.next == null
                  ? null
                  : () => _go(_controller.next),
            ),
          ),
        ],
      ),
    );
  }

  String? _caption() {
    if (!_controller.hasTranslation) return null;
    return _controller.showOriginal ? 'Teks asli' : 'Diterjemahkan otomatis';
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
