import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../data/gateways/library_gateway.dart';
import '../../data/providers/gateway_providers.dart';
import '../../data/providers/source_providers.dart';
import '../../src/rust/dto/library.dart';
import '../../src/rust/dto/sources.dart';
import '../../src/rust/error.dart';
import '../../widgets/error_state_view.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/state_view.dart';
import 'cta_plan.dart';
import 'detail_actions.dart';
import 'detail_body.dart';
import 'detail_cta_bar.dart';
import 'detail_info.dart';
import 'detail_providers.dart';
import 'detail_request.dart';
import 'detail_skeleton.dart';
import 'detail_tabs.dart';
import 'maybe_match.dart';
import 'release_note.dart';
import 'source_names.dart';
import 'source_sheet.dart';

class DetailScreen extends ConsumerStatefulWidget {
  const DetailScreen({super.key, required this.request});

  final DetailRequest request;

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  DetailTab _tab = DetailTab.units;
  String? _source;

  DetailRequest get _request => widget.request;

  LibraryGateway get _library => ref.read(libraryGatewayProvider);

  Future<void> _toggleOrder(bool descending) async {
    await _library.setUnitOrder(
      _request.kind,
      _request.reference,
      descending ? UnitOrderDto.asc : UnitOrderDto.desc,
    );
    ref.invalidate(unitOrderProvider(_request));
  }

  Future<void> _pickSource(List<SourceLinkDto> links, String? current) async {
    final statuses = ref.read(sourceStatusProvider).value ?? const [];
    final chosen = await showSourceSheet(
      context,
      links: links,
      current: current,
      names: sourceNamesOf(statuses, _request.kind),
    );
    if (chosen != null) setState(() => _source = chosen);
  }

  Future<void> _fix(DetailActions actions, String? current, bool manual) async {
    final changed = await actions.fixMatch(
      currentSource: current,
      hasManualChoice: manual,
    );
    if (changed) {
      setState(() => _source = null);
      ref.invalidate(unitsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(detailProvider(_request));
    final scheme = ShadTheme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.background,
      child: SafeArea(
        bottom: false,
        child: detail.when(
          loading: () => const SingleChildScrollView(child: DetailSkeleton()),
          error: (error, stack) => _failure(error),
          data: _content,
        ),
      ),
    );
  }

  Widget _failure(Object error) {
    void retry() => ref.invalidate(detailProvider(_request));
    return Column(
      children: [
        const ScreenHeader(title: ''),
        Expanded(
          child: error is BridgeError
              ? ErrorStateView(error: error, onRetry: retry)
              : StateView.error(
                  title: 'Ada yang tidak beres',
                  message: 'Detail belum bisa dimuat.',
                  actionLabel: 'Coba lagi',
                  onAction: retry,
                ),
        ),
      ],
    );
  }

  Widget _content(DetailViewDto view) {
    final info = DetailInfo.fromView(view, _request.kind);
    final actions = DetailActions(
      context: context,
      ref: ref,
      request: _request,
      info: info,
    );
    final links = view.catalog?.sources ?? const <SourceLinkDto>[];
    final units = ref.watch(
      unitsProvider((request: _request, source: _source)),
    );
    final last = ref.watch(lastProgressProvider(_request)).value;
    final favorite = ref.watch(isFavoriteProvider(_request)).value ?? false;
    final order = ref.watch(unitOrderProvider(_request)).value;
    final current = units.value?.source ?? _source;
    final plan = units.isLoading
        ? const CtaPlan(label: 'Memuat...', enabled: false)
        : planCta(
            kind: _request.kind,
            units: units.value?.units ?? const [],
            last: last,
            isFilm: info.isFilm,
            unreleased: isUnreleased(info.status),
            releaseLabel: releaseDateLabel(info.startDate),
          );
    final manual = links.any((link) => link.manual);
    final doubt = doubtfulLink(
      kind: _request.kind,
      links: links,
      current: current,
    );
    Future<void> guarded(Future<void> Function() play) async {
      if (doubt != null && !await actions.askBeforePlaying(doubt)) return;
      await play();
    }

    return Column(
      children: [
        Expanded(
          child: DetailBody(
            view: view,
            info: info,
            request: _request,
            tab: _tab,
            units: units,
            descending: order == UnitOrderDto.desc,
            focus: last?.unitNumber,
            actions: actions,
            onTab: (tab) => setState(() => _tab = tab),
            onPickSource: () => _pickSource(links, current),
            onWrong: () => _fix(actions, current, manual),
            doubt: doubt,
            onConfirm: () => actions.confirmMatch(doubt!),
            onToggleOrder: () => _toggleOrder(order == UnitOrderDto.desc),
            onRetryUnits: () => ref.invalidate(unitsProvider),
            onPlay: (unit) =>
                guarded(() => actions.play(unit, source: current)),
          ),
        ),
        DetailCtaBar(
          plan: plan,
          isFavorite: favorite,
          onPlay: () => guarded(() => actions.playPlan(plan, source: current)),
          onFavorite: actions.toggleFavorite,
        ),
      ],
    );
  }
}
