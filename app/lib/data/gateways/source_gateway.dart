import '../../src/rust/api/sources.dart' as api;
import '../../src/rust/dto/sources.dart';

abstract interface class SourceGateway {
  Future<List<SourceStatusDto>> status();

  Future<void> setEnabled(String id, bool enabled);
}

class BridgeSourceGateway implements SourceGateway {
  const BridgeSourceGateway();

  @override
  Future<List<SourceStatusDto>> status() => api.sourcesStatus();

  @override
  Future<void> setEnabled(String id, bool enabled) =>
      api.setSourceEnabled(id: id, enabled: enabled);
}
