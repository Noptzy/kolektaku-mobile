import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/gateway_providers.dart';
import '../../src/rust/dto/library.dart';
import '../../src/rust/dto/sources.dart';
import 'detail_request.dart';

typedef UnitsArgs = ({DetailRequest request, String? source});

final detailProvider = FutureProvider.autoDispose
    .family<DetailViewDto, DetailRequest>(
      (ref, request) => ref
          .watch(catalogGatewayProvider)
          .detail(request.kind, request.reference),
    );

final unitsProvider = FutureProvider.autoDispose.family<UnitsDto, UnitsArgs>(
  (ref, args) => ref
      .watch(catalogGatewayProvider)
      .units(args.request.reference, source: args.source),
);

final lastProgressProvider = FutureProvider.autoDispose
    .family<ProgressDto?, DetailRequest>(
      (ref, request) => ref
          .watch(libraryGatewayProvider)
          .lastProgress(request.kind, request.reference),
    );

final isFavoriteProvider = FutureProvider.autoDispose
    .family<bool, DetailRequest>(
      (ref, request) => ref
          .watch(libraryGatewayProvider)
          .isFavorite(request.kind, request.reference),
    );

final unitProgressProvider = FutureProvider.autoDispose
    .family<Map<double, ProgressDto>, DetailRequest>((ref, request) async {
      final history = await ref
          .watch(libraryGatewayProvider)
          .history(request.kind);
      return {
        for (final item in history)
          if (item.reference == request.reference) item.unitNumber: item,
      };
    });

final unitOrderProvider = FutureProvider.autoDispose
    .family<UnitOrderDto, DetailRequest>(
      (ref, request) => ref
          .watch(libraryGatewayProvider)
          .unitOrder(request.kind, request.reference),
    );
