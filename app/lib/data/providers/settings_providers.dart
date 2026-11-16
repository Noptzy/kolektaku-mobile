import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../src/rust/dto/settings.dart';
import 'gateway_providers.dart';

const defaultSettings = SettingsDto(
  prefersAnime: true,
  subtitleLanguage: SubtitleLanguageDto.indonesian,
  subtitleSize: SubtitleSizeDto.medium,
  subtitleColor: SubtitleColorDto.white,
  subtitleEdge: SubtitleEdgeDto.outline,
  subtitleBoxColor: SubtitleBoxColorDto.black,
  subtitleBoxOpacity: SubtitleBoxOpacityDto.off,
  quality: QualityDto.auto,
  autoNext: true,
  autoSkip: false,
  accent: '#F5B82E',
  translation: TranslationLanguageDto.indonesian,
  readingSize: ReadingSizeDto.medium,
  readingSpacing: ReadingSpacingDto.normal,
  continuousReading: true,
);

class SettingsNotifier extends AsyncNotifier<SettingsDto> {
  @override
  Future<SettingsDto> build() => ref.watch(settingsGatewayProvider).load();

  Future<void> change(SettingsDto Function(SettingsDto current) edit) async {
    final previous = state.value ?? defaultSettings;
    final wanted = edit(previous);
    state = AsyncData(wanted);
    try {
      state = AsyncData(await ref.read(settingsGatewayProvider).save(wanted));
    } on Object {
      state = AsyncData(previous);
    }
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, SettingsDto>(
  SettingsNotifier.new,
);

final currentSettingsProvider = Provider<SettingsDto>(
  (ref) => ref.watch(settingsProvider).value ?? defaultSettings,
);
