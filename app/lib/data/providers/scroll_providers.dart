import 'package:flutter_riverpod/flutter_riverpod.dart';

class ScrollToTopSignal extends Notifier<int> {
  @override
  int build() => 0;

  void request() => state++;
}

final homeScrollToTopProvider = NotifierProvider<ScrollToTopSignal, int>(
  ScrollToTopSignal.new,
);
