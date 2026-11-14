import 'package:kolektaku/data/gateways/settings_gateway.dart';
import 'package:kolektaku/data/providers/settings_providers.dart';
import 'package:kolektaku/src/rust/dto/settings.dart';

class FakeSettingsGateway implements SettingsGateway {
  FakeSettingsGateway({SettingsDto? initial})
    : stored = initial ?? defaultSettings;

  SettingsDto stored;
  final List<SettingsDto> saves = [];
  bool failSaves = false;

  @override
  Future<SettingsDto> load() async => stored;

  @override
  Future<SettingsDto> save(SettingsDto settings) async {
    if (failSaves) throw StateError('save failed');
    saves.add(settings);
    stored = settings;
    return settings;
  }
}
