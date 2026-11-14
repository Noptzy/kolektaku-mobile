import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/theme/kolektaku_text.dart';
import '../../../core/theme/kolektaku_tokens.dart';

class TextSamples extends StatelessWidget {
  const TextSamples({super.key});

  @override
  Widget build(BuildContext context) {
    final text = ShadTheme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Spacing.sm,
      children: [
        Text('Kimi no Na wa.', style: text.heroTitle),
        Text('Unggulan hari ini', style: text.sectionTitle),
        Text('Judul kartu dua baris', style: text.cardTitle),
        Text('2016 · 1 eps', style: text.cardMeta),
        Text('SKOR 86', style: text.badge),
        Text('Isi paragraf biasa untuk sinopsis.', style: text.p),
      ],
    );
  }
}
