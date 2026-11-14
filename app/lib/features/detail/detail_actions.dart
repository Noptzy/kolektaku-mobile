import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/routes.dart';
import '../../data/providers/gateway_providers.dart';
import '../../platform/trailer_embed.dart';
import '../../platform/url_opener.dart';
import '../../src/rust/dto/credits.dart';
import '../../src/rust/dto/library.dart';
import '../../src/rust/dto/media.dart';
import '../../src/rust/dto/sources.dart';
import '../profile/profile_request.dart';
import '../reader/read_request.dart';
import '../watch/watch_request.dart';
import 'cta_plan.dart';
import 'detail_info.dart';
import 'detail_providers.dart';
import 'detail_request.dart';
import 'link_style.dart';
import 'trailer_sheet.dart';
import 'wrong_match_sheet.dart';

class DetailActions {
  const DetailActions({
    required this.context,
    required this.ref,
    required this.request,
    required this.info,
  });

  final BuildContext context;
  final WidgetRef ref;
  final DetailRequest request;
  final DetailInfo info;

  void _refreshProgress() {
    ref.invalidate(lastProgressProvider(request));
    ref.invalidate(unitProgressProvider(request));
  }

  Future<void> play(UnitDto unit, {Duration? startAt, String? source}) async {
    final target = request.kind == MediaKindDto.anime
        ? Routes.watch
        : Routes.read;
    final Object extra = request.kind == MediaKindDto.anime
        ? WatchRequest(
            reference: request.reference,
            kind: request.kind,
            title: info.title,
            episode: unit.number,
            coverUrl: info.coverUrl,
            startAt: startAt,
            preferredSource: source,
            synopsis: info.synopsis,
          )
        : ReadRequest(
            reference: request.reference,
            title: info.title,
            chapter: unit.number,
            coverUrl: info.coverUrl,
            preferredSource: source,
          );
    await context.push(target, extra: extra);
    _refreshProgress();
  }

  Future<void> playPlan(CtaPlan plan, {String? source}) async {
    final unit = plan.unit;
    if (unit == null) return;
    await play(unit, startAt: plan.startAt, source: source);
  }

  Future<void> toggleFavorite() async {
    final favorite = FavoriteDto(
      reference: request.reference,
      kind: request.kind,
      title: info.title,
      coverUrl: info.coverUrl,
      addedAtSecs: BigInt.from(DateTime.now().millisecondsSinceEpoch ~/ 1000),
    );
    final added = await ref
        .read(libraryGatewayProvider)
        .toggleFavorite(favorite);
    ref.invalidate(isFavoriteProvider(request));
    if (!context.mounted) return;
    ShadToaster.of(context).show(
      ShadToast(
        description: Text(
          added ? 'Ditambahkan ke favorit.' : 'Dihapus dari favorit.',
        ),
      ),
    );
  }

  Future<void> openTrailer(TrailerDto trailer) async {
    if (trailerEmbedUrl(trailer.site, trailer.videoId) != null) {
      await showTrailerSheet(context, trailer);
      return;
    }
    final url = trailerUrl(trailer.site, trailer.videoId);
    if (url == null) return;
    await ref.read(urlOpenerProvider).open(url);
  }

  Future<void> openLink(String url) async {
    if (!openableLink(url)) return;
    await ref.read(urlOpenerProvider).open(url);
  }

  void openSummary(MediaSummaryDto summary) {
    context.push(Routes.detail, extra: DetailRequest.catalog(summary));
  }

  void openProfile(ProfileRequest profile) {
    context.push(Routes.profile, extra: profile);
  }

  Future<bool> fixMatch({
    required String? currentSource,
    required bool hasManualChoice,
  }) async {
    final choice = await showWrongMatchSheet(
      context,
      kind: request.kind,
      title: info.title,
      currentSource: currentSource,
      hasManualChoice: hasManualChoice,
    );
    if (choice == null) return false;
    final gateway = ref.read(catalogGatewayProvider);
    if (choice.forget) {
      await gateway.forgetMatch(request.kind, request.reference);
    } else {
      await gateway.selectSource(
        request.kind,
        request.reference,
        choice.source!,
        choice.item!,
      );
    }
    ref.invalidate(detailProvider(request));
    return true;
  }
}
