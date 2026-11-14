import 'package:kolektaku/data/gateways/source_gateway.dart';
import 'package:kolektaku/src/rust/dto/sources.dart';

class FakeSourceGateway implements SourceGateway {
  List<SourceStatusDto> statuses = const [];
  final List<String> toggles = [];

  @override
  Future<List<SourceStatusDto>> status() async => statuses;

  @override
  Future<void> setEnabled(String id, bool enabled) async {
    toggles.add('$id|$enabled');
    statuses = [
      for (final item in statuses)
        item.id == id
            ? SourceStatusDto(
                id: item.id,
                name: item.name,
                kind: item.kind,
                enabled: enabled,
                skipped: item.skipped,
                summary: item.summary,
              )
            : item,
    ];
  }
}
