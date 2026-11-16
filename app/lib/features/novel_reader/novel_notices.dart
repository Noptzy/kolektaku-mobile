import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../src/rust/dto/novel.dart';

void announceChapter(BuildContext context, NovelChapterDto view) {
  final toaster = ShadToaster.of(context);
  if (view.switchedFrom != null) {
    toaster.show(
      const ShadToast(description: Text('Dibaca dari sumber lain.')),
    );
  }
  if (view.translationFailed) {
    toaster.show(
      const ShadToast(
        description: Text(
          'Terjemahan belum bisa dimuat. Teks asli yang tampil.',
        ),
      ),
    );
  }
}
