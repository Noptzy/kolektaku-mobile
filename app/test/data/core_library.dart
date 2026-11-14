import 'dart:io';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:kolektaku/src/rust/api/session.dart' as core;
import 'package:kolektaku/src/rust/frb_generated.dart';

const hostLibraryPath = '../core/target/debug/bridge.dll';

bool get hostLibraryMissing => !File(hostLibraryPath).existsSync();

String get missingReason =>
    'build it first: cargo build --manifest-path ../core/Cargo.toml -p bridge';

Future<Directory> startHostCore() async {
  await RustLib.init(externalLibrary: ExternalLibrary.open(hostLibraryPath));
  final folder = await Directory.systemTemp.createTemp('kolektaku-core-test-');
  await core.init(appDir: folder.path, appVersion: '0.0.0-test');
  return folder;
}
