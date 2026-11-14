import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/gateway_providers.dart';
import '../../src/rust/dto/profile.dart';
import 'profile_request.dart';

final profileProvider = FutureProvider.autoDispose
    .family<ProfileDto, ProfileRequest>(
      (ref, request) =>
          ref.watch(catalogGatewayProvider).profile(request.kind, request.id),
    );
