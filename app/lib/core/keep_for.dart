import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

const detailKeepAlive = Duration(minutes: 10);

extension KeepFor on Ref {
  void keepFor(Duration lifetime) {
    final link = keepAlive();
    final timer = Timer(lifetime, link.close);
    onDispose(timer.cancel);
  }
}
