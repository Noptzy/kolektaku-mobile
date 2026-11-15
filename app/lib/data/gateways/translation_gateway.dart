import '../../src/rust/api/translate.dart' as api;
import '../../src/rust/dto/translate.dart';

abstract interface class TranslationGateway {
  Future<TextTranslationDto> translate(List<String> texts);

  Future<int?> pausedUntilSecs();
}

class BridgeTranslationGateway implements TranslationGateway {
  const BridgeTranslationGateway();

  @override
  Future<TextTranslationDto> translate(List<String> texts) =>
      api.translateTexts(texts: texts);

  @override
  Future<int?> pausedUntilSecs() async =>
      (await api.translationPausedUntil())?.toInt();
}
