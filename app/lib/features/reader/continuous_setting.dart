import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/settings_providers.dart';

class WithContinuous extends ConsumerWidget {
  const WithContinuous({super.key, required this.builder});

  final Widget Function(bool autoContinue) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return builder(ref.read(currentSettingsProvider).continuousReading);
  }
}
