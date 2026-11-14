import 'package:flutter/widgets.dart';
import 'package:kolektaku/src/rust/frb_generated.dart';

import 'app.dart';
import 'app_scope.dart';
import 'data/core_session.dart';
import 'features/splash/kolektaku_boot.dart';

Future<void> prepareCore() async {
  await RustLib.init();
  await startCore();
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    KolektakuBoot(
      init: prepareCore,
      app: (context) => kolektakuScope(child: const KolektakuApp()),
    ),
  );
}
