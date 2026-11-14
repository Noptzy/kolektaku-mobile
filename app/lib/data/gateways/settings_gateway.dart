import '../../src/rust/api/settings.dart' as api;
import '../../src/rust/dto/settings.dart';

abstract interface class SettingsGateway {
  Future<SettingsDto> load();

  Future<SettingsDto> save(SettingsDto settings);
}

class BridgeSettingsGateway implements SettingsGateway {
  const BridgeSettingsGateway();

  @override
  Future<SettingsDto> load() => api.getSettings();

  @override
  Future<SettingsDto> save(SettingsDto settings) =>
      api.saveSettings(settings: settings);
}
