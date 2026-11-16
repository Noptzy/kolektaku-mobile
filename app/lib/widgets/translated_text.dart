import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/theme/kolektaku_tokens.dart';
import '../data/providers/translation_providers.dart';
import 'pressable.dart';

class TranslatedText extends ConsumerStatefulWidget {
  const TranslatedText({
    super.key,
    required this.text,
    this.style,
    this.maxLines,
    this.overflow,
    this.showNote = true,
    this.textKey,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool showNote;
  final Key? textKey;

  @override
  ConsumerState<TranslatedText> createState() => _TranslatedTextState();
}

class _TranslatedTextState extends ConsumerState<TranslatedText> {
  bool _showingOriginal = false;

  @override
  Widget build(BuildContext context) {
    final shown = shownFor(
      ref.watch(translatedTextsProvider(TextBatch([widget.text]))),
      [widget.text],
    );
    final visible = shown.translated && !_showingOriginal
        ? shown.texts.single
        : widget.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Spacing.xs,
      children: [
        Text(
          visible,
          key: widget.textKey,
          style: widget.style,
          maxLines: widget.maxLines,
          overflow: widget.overflow,
        ),
        if (shown.translated && widget.showNote)
          _Note(
            showingOriginal: _showingOriginal,
            onToggle: () =>
                setState(() => _showingOriginal = !_showingOriginal),
          ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.showingOriginal, required this.onToggle});

  final bool showingOriginal;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final scheme = theme.colorScheme;
    final label = showingOriginal ? 'Teks asli' : 'Diterjemahkan otomatis';
    final action = showingOriginal ? 'Lihat terjemahan' : 'Lihat asli';
    return Pressable(
      key: const Key('translation-note'),
      onTap: onToggle,
      label: '$label, $action',
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label · ',
              style: theme.textTheme.small.copyWith(
                color: scheme.mutedForeground,
              ),
            ),
            TextSpan(
              text: action,
              style: theme.textTheme.small.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
