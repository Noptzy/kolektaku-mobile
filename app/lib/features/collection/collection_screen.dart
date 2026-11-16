import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/routes.dart';
import '../../core/theme/kolektaku_tokens.dart';
import '../../data/providers/home_providers.dart';
import '../../data/providers/library_providers.dart';
import '../../src/rust/dto/highlight.dart';
import '../../src/rust/dto/library.dart';
import '../../src/rust/dto/media.dart';
import '../../widgets/kind_switch.dart';
import '../../widgets/refresh_on_visible.dart';
import '../detail/detail_request.dart';
import 'history_launch.dart';
import 'collection_actions.dart';
import 'collection_sections.dart';
import 'highlights_section.dart';

class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key});

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  MediaKindDto _kind = MediaKindDto.anime;

  Future<void> _open(MediaRefDto reference) async {
    await context.push(
      Routes.detail,
      extra: DetailRequest(kind: _kind, reference: reference),
    );
    _refresh();
  }

  Future<void> _openHistory(ProgressDto item) async {
    await context.push(historyRoute(item), extra: historyRequest(item));
    _refresh();
  }

  Future<void> _openHighlight(HighlightDto item) async {
    await context.push(Routes.novel, extra: highlightRequest(item));
    _refresh();
  }

  void _refresh() {
    if (!mounted) return;
    ref.invalidate(highlightsProvider);
    for (final kind in MediaKindDto.values) {
      ref.invalidate(continueProvider(kind));
      ref.invalidate(favoritesProvider(kind));
      ref.invalidate(historyProvider(kind));
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = CollectionActions(context: context, ref: ref, kind: _kind);
    final resume = ref.watch(continueProvider(_kind));
    final favorites = ref.watch(favoritesProvider(_kind));
    final history = ref.watch(historyProvider(_kind));
    return RefreshOnVisible(
      onVisible: _refresh,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _header(context)),
          SliverToBoxAdapter(
            child: KindSwitch(
              value: _kind,
              onChanged: (kind) => setState(() => _kind = kind),
            ),
          ),
          ...resume.when(
            data: (items) =>
                continueSection(_kind, items, (item) => _open(item.reference)),
            loading: () => const [],
            error: (error, stack) => const [],
          ),
          if (_kind == MediaKindDto.novel)
            ...ref
                .watch(highlightsProvider)
                .when(
                  data: (items) => highlightsSection(
                    items,
                    _openHighlight,
                    actions.removeHighlight,
                  ),
                  loading: () => const [
                    SliverToBoxAdapter(child: SectionLoading()),
                  ],
                  error: (error, stack) => const [
                    SliverToBoxAdapter(
                      child: EmptyNote(text: 'Sorotan belum bisa dimuat.'),
                    ),
                  ],
                ),
          ...favorites.when(
            data: (items) => favoritesSection(
              _kind,
              items,
              (item) => _open(item.reference),
              actions.removeFavorite,
            ),
            loading: () => const [SliverToBoxAdapter(child: SectionLoading())],
            error: (error, stack) => [
              SliverToBoxAdapter(
                child: EmptyNote(text: 'Favorit belum bisa dimuat.'),
              ),
            ],
          ),
          ...history.when(
            data: (items) => historySection(
              _kind,
              items,
              _openHistory,
              actions.removeHistory,
              actions.clearHistory,
            ),
            loading: () => const [SliverToBoxAdapter(child: SectionLoading())],
            error: (error, stack) => [
              SliverToBoxAdapter(
                child: EmptyNote(text: 'Riwayat belum bisa dimuat.'),
              ),
            ],
          ),
          const SliverToBoxAdapter(child: SizedBox(height: Spacing.xxl)),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.screenGutter,
        Spacing.md,
        Spacing.sm,
        Spacing.sm,
      ),
      child: Row(
        children: [
          Expanded(child: Text('Koleksiku', style: theme.textTheme.h3)),
          ShadIconButton.ghost(
            key: const Key('open-settings'),
            icon: const Icon(LucideIcons.settings),
            onPressed: () => context.go(Routes.settings),
          ),
        ],
      ),
    );
  }
}
