import 'package:flutter/foundation.dart';

import '../../data/gateways/source_gateway.dart';
import '../../src/rust/dto/sources.dart';

class SourcePingBoard extends ChangeNotifier {
  SourcePingBoard(this.gateway);

  final SourceGateway gateway;
  final Map<String, SourcePingDto> results = {};
  final Set<String> checking = {};
  bool _disposed = false;

  bool get busy => checking.isNotEmpty;

  Future<void> check(Iterable<String> ids) async {
    final wanted = ids.where((id) => !checking.contains(id)).toList();
    if (wanted.isEmpty) return;
    checking.addAll(wanted);
    results.removeWhere((id, result) => wanted.contains(id));
    _tell();
    await Future.wait([for (final id in wanted) _one(id)]);
  }

  Future<void> _one(String id) async {
    try {
      results[id] = await gateway.ping(id);
    } on Object {
      results[id] = SourcePingDto(
        id: id,
        verdict: PingVerdictDto.offline,
        millis: 0,
      );
    } finally {
      checking.remove(id);
      _tell();
    }
  }

  void _tell() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
