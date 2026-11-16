import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/routes.dart';
import '../../src/rust/dto/media.dart';
import '../../widgets/filter_sheet.dart';
import 'media_search_body.dart';
import 'search_filter_menu.dart';
import 'search_filters.dart';
import 'search_notifier.dart';
import 'search_seed.dart';
import 'search_tab_header.dart';

const searchPlaceholder = 'Cari anime, komik, novel, karakter, studio';

class SearchTabScreen extends ConsumerStatefulWidget {
  const SearchTabScreen({super.key});

  @override
  ConsumerState<SearchTabScreen> createState() => _SearchTabScreenState();
}

class _SearchTabScreenState extends ConsumerState<SearchTabScreen> {
  final TextEditingController _controller = TextEditingController();
  MediaKindDto _kind = MediaKindDto.anime;

  SearchNotifier get _notifier => ref.read(searchProvider(_kind).notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final seed = ref.read(searchSeedProvider);
      if (mounted && seed != null) _plant(seed);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _typed(String text) {
    if (_kind != MediaKindDto.anime && text.trim().isNotEmpty) {
      setState(() => _kind = MediaKindDto.anime);
    }
    _notifier.onQueryChanged(text);
  }

  void _submitted(String text) => _notifier.submit();

  Future<void> _plant(SearchSeed seed) async {
    ref.read(searchSeedProvider.notifier).consume();
    _controller.text = seed.query;
    if (seed.kind != _kind) {
      setState(() => _kind = seed.kind);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
    }
    final notifier = ref.read(searchProvider(seed.kind).notifier);
    notifier.onQueryChanged(seed.query);
    await notifier.applyFilters(
      format: seed.format,
      order: SearchOrder.relevance,
      genre: seed.genre,
      airing: seed.airing,
      origin: seed.origin,
    );
  }

  void _searchFor(String text) {
    if (!mounted) return;
    _controller.text = text;
    _typed(text);
    _notifier.submit();
  }

  Future<void> _openFilters() async {
    final state = ref.read(searchProvider(_kind));
    final choice = await showFilterSheet(
      context,
      sections: searchSections(_kind, DateTime.now().year),
      current: searchChoice(state),
      initial: searchInitialChoice,
      links: _kind == MediaKindDto.anime ? studioLinks(_searchFor) : null,
    );
    if (choice != null) await applySearchChoice(_notifier, choice);
  }

  int _activeCount() {
    final state = ref.watch(searchProvider(_kind));
    return activeSearchFilters(state, _notifier).length;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SearchSeed?>(searchSeedProvider, (previous, next) {
      if (next != null) _plant(next);
    });
    return ColoredBox(
      color: ShadTheme.of(context).colorScheme.background,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SearchTabHeader(
              controller: _controller,
              placeholder: searchPlaceholder,
              onChanged: _typed,
              onSubmitted: _submitted,
              onCamera: () => context.push(Routes.sceneSearch),
              onFilter: _openFilters,
              filterCount: _activeCount(),
            ),
            Expanded(
              child: MediaSearchBody(
                key: ValueKey(_kind),
                kind: _kind,
                controller: _controller,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
