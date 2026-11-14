import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/keep_for.dart';
import '../../data/providers/gateway_providers.dart';
import '../../src/rust/dto/profile.dart';
import 'profile_request.dart';

final profileProvider = FutureProvider.autoDispose
    .family<ProfileDto, ProfileRequest>((ref, request) {
      ref.keepFor(detailKeepAlive);
      return ref
          .watch(catalogGatewayProvider)
          .profile(request.kind, request.id);
    });
