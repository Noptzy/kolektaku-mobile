import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routes.dart';
import '../../src/rust/dto/credits.dart';
import '../../src/rust/dto/media.dart';
import '../../src/rust/dto/profile.dart';
import '../../src/rust/dto/studio.dart';
import '../profile/profile_request.dart';
import '../search/search_filters.dart';
import '../search/search_seed.dart';

void searchFrom(BuildContext context, WidgetRef ref, SearchSeed seed) {
  openSearchWith(context, ref, seed);
}

void openStudioFrom(BuildContext context, WidgetRef ref, StudioRefDto studio) {
  final id = studio.id;
  if (id == null) {
    openSearchWith(context, ref, SearchSeed(query: studio.name));
    return;
  }
  context.push(
    Routes.profile,
    extra: ProfileRequest(
      kind: ProfileKindDto.studio,
      id: id,
      name: studio.name,
    ),
  );
}

Map<String, VoidCallback> infoActionsOf(
  BuildContext context,
  WidgetRef ref,
  MediaDetailDto detail,
  MediaKindDto kind,
) {
  final scope = kind;
  final summary = detail.summary;
  final format = formatSeedOf(summary.format);
  final airing = airingSeedOf(summary.status);
  final origin = originSeedOf(detail.source);
  return {
    if (format != SearchFormat.all)
      'Format': () =>
          searchFrom(context, ref, SearchSeed(kind: scope, format: format)),
    if (airing.apiName != null)
      'Status': () =>
          searchFrom(context, ref, SearchSeed(kind: scope, airing: airing)),
    if (origin.apiName != null)
      'Sumber cerita': () =>
          searchFrom(context, ref, SearchSeed(kind: scope, origin: origin)),
  };
}
