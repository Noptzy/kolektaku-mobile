import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

Duration? noRetry(int count, Object error) => null;

Widget kolektakuScope({
  required Widget child,
  List<Override> overrides = const [],
}) {
  return ProviderScope(retry: noRetry, overrides: overrides, child: child);
}
