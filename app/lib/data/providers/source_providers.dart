import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../src/rust/dto/media.dart';
import '../../src/rust/dto/sources.dart';
import 'gateway_providers.dart';

final sourceStatusProvider = FutureProvider.autoDispose<List<SourceStatusDto>>(
  (ref) => ref.watch(sourceGatewayProvider).status(),
);

final enabledSourcesProvider = FutureProvider.autoDispose
    .family<List<SourceStatusDto>, MediaKindDto>((ref, kind) async {
      final all = await ref.watch(sourceStatusProvider.future);
      return all.where((item) => item.kind == kind && item.enabled).toList();
    });

typedef CandidateArgs = ({String source, String query});

final candidatesProvider = FutureProvider.autoDispose
    .family<List<SourceItemDto>, CandidateArgs>(
      (ref, args) => ref
          .watch(catalogGatewayProvider)
          .sourceCandidates(args.source, args.query),
    );
