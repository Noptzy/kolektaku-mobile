import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/library.dart';
import '../../src/rust/dto/sources.dart';
import '../profile/profile_request.dart';
import 'characters_section.dart';
import 'detail_actions.dart';
import 'detail_extras.dart';
import 'detail_header.dart';
import 'detail_info.dart';
import 'detail_providers.dart';
import 'detail_request.dart';
import 'detail_synopsis.dart';
import 'detail_tabs.dart';
import '../search/search_seed.dart';
import 'info_links.dart';
import 'info_section.dart';
import 'maybe_match_note.dart';
import 'release_note.dart';
import 'related_section.dart';
import 'source_note.dart';
import 'source_row.dart';
import 'units_sliver.dart';

class DetailBody extends ConsumerWidget {
  const DetailBody({
    super.key,
    required this.view,
    required this.info,
    required this.request,
    required this.tab,
    required this.units,
    required this.descending,
    required this.focus,
    required this.actions,
    required this.onTab,
    required this.onPickSource,
    required this.onWrong,
    required this.doubt,
    required this.onConfirm,
    required this.onToggleOrder,
    required this.onRetryUnits,
    required this.onPlay,
  });

  final DetailViewDto view;
  final DetailInfo info;
  final DetailRequest request;
  final DetailTab tab;
  final AsyncValue<UnitsDto> units;
  final bool descending;
  final double? focus;
  final DetailActions actions;
  final ValueChanged<DetailTab> onTab;
  final VoidCallback onPickSource;
  final VoidCallback onWrong;
  final SourceLinkDto? doubt;
  final VoidCallback onConfirm;
  final VoidCallback onToggleOrder;
  final VoidCallback onRetryUnits;
  final ValueChanged<UnitDto> onPlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(unitProgressProvider(request)).value ?? const {};
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: DetailHeader(info: info)),
        const SliverToBoxAdapter(child: SizedBox(height: Spacing.lg)),
        if (request.notice != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.screenGutter,
                0,
                Spacing.screenGutter,
                Spacing.lg,
              ),
              child: ShadAlert(
                key: const Key('detail-notice'),
                description: Text(request.notice!),
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: DetailSynopsis(
            info: info,
            onGenre: (genre) => searchFrom(
              context,
              ref,
              SearchSeed(kind: request.kind, genre: genre),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: DetailExtras(
            view: view,
            info: info,
            kind: request.kind,
            actions: actions,
          ),
        ),
        SliverToBoxAdapter(
          child: SourceRow(
            canPick: (view.catalog?.sources.length ?? 0) > 1,
            onPick: onPickSource,
            onWrong: onWrong,
          ),
        ),
        if (doubt != null)
          SliverToBoxAdapter(
            child: MaybeMatchNote(
              link: doubt!,
              onYes: onConfirm,
              onNo: onWrong,
            ),
          ),
        SliverToBoxAdapter(
          child: SourceNote(
            kind: request.kind,
            source: units.value?.source,
            loaded: units.value?.units.length,
            expected: info.unitCount,
            canSwitch: (view.catalog?.sources.length ?? 0) > 1,
          ),
        ),
        SliverToBoxAdapter(
          child: DetailTabs(
            selected: tab,
            kind: request.kind,
            onChanged: onTab,
          ),
        ),
        ..._tabContent(context, ref, progress),
        const SliverToBoxAdapter(child: SizedBox(height: Spacing.xxl)),
      ],
    );
  }

  List<Widget> _tabContent(
    BuildContext context,
    WidgetRef ref,
    Map<double, ProgressDto> progress,
  ) {
    final catalog = view.catalog;
    return switch (tab) {
      DetailTab.units => [
        UnitsSliver(
          units: units,
          view: view,
          kind: request.kind,
          progress: progress,
          descending: descending,
          focus: focus,
          onToggleOrder: onToggleOrder,
          onRetry: onRetryUnits,
          onPlay: onPlay,
          onWrong: onWrong,
          unreleased: isUnreleased(info.status),
          releaseLabel: releaseDateLabel(info.startDate),
        ),
      ],
      DetailTab.characters => [
        CharactersSection(
          characters: catalog?.detail.characters ?? const [],
          onCharacter: (character) =>
              actions.openProfile(ProfileRequest.character(character)),
          onVoiceActor: (actor) =>
              actions.openProfile(ProfileRequest.voiceActor(actor)),
        ),
      ],
      DetailTab.info => [
        InfoSection(
          rows: catalog != null
              ? infoRows(catalog.detail, request.kind)
              : siteInfoRows(view.site!),
          actions: catalog == null
              ? const {}
              : infoActionsOf(context, ref, catalog.detail, request.kind),
          studios: catalog?.detail.studios ?? const [],
          onStudio: (studio) => openStudioFrom(context, ref, studio),
        ),
      ],
      DetailTab.related => [
        RelatedSection(
          relations: catalog?.detail.relations ?? const [],
          recommendations: catalog?.detail.recommendations ?? const [],
          onOpen: actions.openSummary,
        ),
      ],
    };
  }
}
