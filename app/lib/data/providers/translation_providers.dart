import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../src/rust/dto/settings.dart';
import '../../src/rust/dto/translate.dart';
import 'gateway_providers.dart';
import 'settings_providers.dart';

@immutable
class TextBatch {
  const TextBatch(this.texts);

  final List<String> texts;

  @override
  bool operator ==(Object other) =>
      other is TextBatch && listEquals(other.texts, texts);

  @override
  int get hashCode => Object.hashAll(texts);
}

class TextsShown {
  const TextsShown({required this.texts, required this.translated});

  final List<String> texts;
  final bool translated;
}

final translatedTextsProvider =
    FutureProvider.family<TextTranslationDto?, TextBatch>((ref, batch) async {
      final settings = await ref.watch(settingsProvider.future);
      final hasText = batch.texts.any((text) => text.trim().isNotEmpty);
      if (settings.translation == TranslationLanguageDto.off || !hasText) {
        return null;
      }
      try {
        return await ref
            .read(translationGatewayProvider)
            .translate(batch.texts);
      } on Object {
        return null;
      }
    });

TextsShown shownFor(
  AsyncValue<TextTranslationDto?> result,
  List<String> texts,
) {
  final answer = result.value;
  final usable =
      answer != null &&
      answer.translated &&
      answer.texts.length == texts.length;
  return TextsShown(texts: usable ? answer.texts : texts, translated: usable);
}

final translationPauseProvider = FutureProvider.autoDispose<int?>(
  (ref) => ref.read(translationGatewayProvider).pausedUntilSecs(),
);
