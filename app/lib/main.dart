import 'package:flutter/widgets.dart';
import 'package:kolektaku/src/rust/frb_generated.dart';

import 'app.dart';

Future<void> main() async {
  await RustLib.init();
  runApp(const KolektakuApp());
}
