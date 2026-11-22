import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../platform/haptics.dart';

final hapticsProvider = Provider<Haptics>((ref) => const DeviceHaptics());
