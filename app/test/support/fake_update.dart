import 'package:kolektaku/data/gateways/update_gateway.dart';
import 'package:kolektaku/platform/apk_installer.dart';
import 'package:kolektaku/src/rust/dto/update.dart';

UpdateOfferDto offerOf({
  String version = '2.1.0',
  String notes = 'Perbaikan pemutar.',
  int size = 4 * 1024 * 1024,
  bool required = false,
}) {
  return UpdateOfferDto(
    version: version,
    notes: notes,
    abi: 'arm64-v8a',
    url: 'https://example.test/k.apk',
    size: BigInt.from(size),
    sha256: 'abc',
    required_: required,
  );
}

UpdateProgressDto progressOf(int received, int total, {String? path}) {
  return UpdateProgressDto(
    received: BigInt.from(received),
    total: BigInt.from(total),
    path: path,
  );
}

class FakeUpdateGateway implements UpdateGateway {
  UpdateOfferDto? offer;
  Object? checkError;
  Object? downloadError;
  bool dueResult = true;
  List<UpdateProgressDto> events = const [];
  final List<(String, List<String>)> checks = [];
  final List<({int? last, int now, bool manual})> dueAsks = [];
  final List<String> downloads = [];

  @override
  Future<UpdateOfferDto?> check(String installed, List<String> abis) async {
    checks.add((installed, abis));
    final error = checkError;
    if (error != null) throw error;
    return offer;
  }

  @override
  Stream<UpdateProgressDto> download(
    UpdateOfferDto offer,
    String folder,
  ) async* {
    downloads.add(folder);
    for (final event in events) {
      yield event;
    }
    final error = downloadError;
    if (error != null) throw error;
  }

  @override
  bool due(int? lastCheckedSecs, int nowSecs, {required bool manual}) {
    dueAsks.add((last: lastCheckedSecs, now: nowSecs, manual: manual));
    return dueResult;
  }
}

class FakeApkInstaller implements ApkInstaller {
  List<String> abiList = const ['arm64-v8a', 'armeabi-v7a'];
  Object? installError;
  final List<String> installed = [];

  @override
  Future<List<String>> abis() async => abiList;

  @override
  Future<void> install(String path) async {
    final error = installError;
    if (error != null) throw error;
    installed.add(path);
  }
}
