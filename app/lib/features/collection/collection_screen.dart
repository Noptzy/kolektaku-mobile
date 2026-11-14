import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/routes.dart';
import '../../core/theme/kolektaku_tokens.dart';
import '../../data/providers/home_providers.dart';
import '../../data/providers/library_providers.dart';
import '../../src/rust/dto/media.dart';
import '../../widgets/option_chip.dart';
import '../detail/detail_request.dart';
import 'collection_actions.dart';
import 'collection_logic.dart';
import 'collection_sections.dart';

typedef NowSecs = int Function();

int systemNowSecs() => DateTime.now().millisecondsSinceEpoch ~/ 1000;

class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key, this.now = systemNowSecs});

  final NowSecs now;

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  MediaKindDto _kind = MediaKindDto.anime;

  void _open(MediaRefDto reference) {
    context.push(
      Routes.detail,
      extra: DetailRequest(kind: _kind, reference: reference),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actions = CollectionActions(context: context, ref: ref, kind: _kind);
    final resume = ref.watch(continueProvider(_kind));
    final favorites = ref.watch(favoritesProvider(_kind));
    final history = ref.watch(historyProvider(_kind));
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _header(context)),
        SliverToBoxAdapter(child: _kinds()),
        ...resume.when(
          data: (items) =>
              continueSection(_kind, items, (item) => _open(item.reference)),
          loading: () => const [],
          error: (error, stack) => const [],
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
            widget.now(),
            (item) => _open(item.reference),
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
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
    );
  }

  Widget _kinds() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.screenGutter),
      child: Row(
        spacing: Spacing.sm,
        children: [
          for (final kind in MediaKindDto.values)
            OptionChip(
              key: Key('kind-${kind.name}'),
              label: collectionTitle(kind),
              selected: kind == _kind,
              onTap: () => setState(() => _kind = kind),
            ),
        ],
      ),
    );
  }
}
