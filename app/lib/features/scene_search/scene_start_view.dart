import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import 'picture_buttons.dart';
import 'quota_note.dart';
import 'scene_examples.dart';
import 'scene_steps.dart';

class SceneStartView extends StatelessWidget {
  const SceneStartView({
    super.key,
    required this.onCamera,
    required this.onFiles,
    required this.quotaLeft,
  });

  final VoidCallback onCamera;
  final VoidCallback onFiles;
  final int? quotaLeft;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.all(Spacing.screenGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Spacing.lg,
        children: [
          Text(
            'Pilih tangkapan layar dari anime, lalu kami carikan judul, '
            'episode, dan menitnya.',
            style: theme.textTheme.muted,
          ),
          Center(
            child: PictureButtons(onCamera: onCamera, onFiles: onFiles),
          ),
          QuotaNote(left: quotaLeft, padded: false),
          const SceneSteps(),
          const SceneExamples(),
          Text(
            'Hanya frame anime asli yang dikenali. Foto layar miring atau '
            'gambar buatan penggemar sering gagal.',
            style: theme.textTheme.small,
          ),
        ],
      ),
    );
  }
}
