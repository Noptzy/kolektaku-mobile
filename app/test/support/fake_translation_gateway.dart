import 'package:kolektaku/data/gateways/translation_gateway.dart';
import 'package:kolektaku/src/rust/dto/translate.dart';

class FakeTranslationGateway implements TranslationGateway {
  String Function(String text)? translating;
  Object? failure;
  int? pausedUntil;
  final List<List<String>> asked = [];

  @override
  Future<TextTranslationDto> translate(List<String> texts) async {
    asked.add(texts);
    final error = failure;
    if (error != null) throw error;
    final translate = translating;
    if (translate == null) {
      return TextTranslationDto(texts: texts, translated: false, failed: false);
    }
    return TextTranslationDto(
      texts: [for (final text in texts) translate(text)],
      translated: true,
      failed: false,
    );
  }

  @override
  Future<int?> pausedUntilSecs() async => pausedUntil;
}
