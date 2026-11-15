import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccentPreviewNotifier extends Notifier<Color?> {
  @override
  Color? build() => null;

  void set(Color? accent) => state = accent;
}

final accentPreviewProvider = NotifierProvider<AccentPreviewNotifier, Color?>(
  AccentPreviewNotifier.new,
);
