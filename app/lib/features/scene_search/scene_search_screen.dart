import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/pesan_error.dart';
import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/error.dart';
import '../../widgets/error_state_view.dart';
import '../../widgets/clip_radius.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/state_view.dart';
import 'picture_buttons.dart';
import 'quota_note.dart';
import 'scene_candidate_row.dart';
import 'scene_launch.dart';
import 'scene_notifier.dart';
import 'scene_start_view.dart';
import 'scene_state.dart';

class SceneSearchScreen extends ConsumerStatefulWidget {
  const SceneSearchScreen({
    super.key,
    this.initialImage,
    this.openCamera = false,
  });

  final Uint8List? initialImage;
  final bool openCamera;

  @override
  ConsumerState<SceneSearchScreen> createState() => _SceneSearchScreenState();
}

class _SceneSearchScreenState extends ConsumerState<SceneSearchScreen> {
  @override
  void initState() {
    super.initState();
    final image = widget.initialImage;
    final notifier = ref.read(sceneSearchProvider.notifier);
    if (image != null) {
      Future.microtask(() => notifier.search(image));
    } else if (widget.openCamera) {
      Future.microtask(notifier.takePhoto);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sceneSearchProvider);
    final notifier = ref.read(sceneSearchProvider.notifier);
    ref.listen(sceneSearchProvider, (previous, next) {
      final launch = next.launch;
      if (launch == null || identical(launch, previous?.launch)) return;
      notifier.launched();
      launchScene(context, launch);
    });
    return ColoredBox(
      color: ShadTheme.of(context).colorScheme.background,
      child: SafeArea(
        child: ListView(
          children: [
            const ScreenHeader(title: 'Cari dari gambar'),
            ..._preview(state),
            ..._body(state, notifier),
          ],
        ),
      ),
    );
  }

  List<Widget> _preview(SceneSearchState state) {
    final image = state.image;
    if (image == null) return const [];
    return [
      Padding(
        padding: const EdgeInsets.all(Spacing.screenGutter),
        child: ClipRadius(
          radius: Radii.card,
          child: SizedBox(
            height: 180,
            child: Image.memory(image, fit: BoxFit.cover),
          ),
        ),
      ),
    ];
  }

  List<Widget> _body(SceneSearchState state, SceneSearchNotifier notifier) {
    final theme = ShadTheme.of(context);
    return switch (state.status) {
      SceneStatus.idle => [
        SceneStartView(
          onCamera: notifier.takePhoto,
          onFiles: notifier.pickFromGallery,
          onSample: notifier.trySample,
          quotaLeft: state.quotaLeft,
        ),
      ],
      SceneStatus.searching || SceneStatus.opening => [
        _working(
          state.status == SceneStatus.searching
              ? 'Mencari adegan...'
              : 'Membuka adegan...',
        ),
      ],
      SceneStatus.failed => [_failure(state, notifier)],
      SceneStatus.notFound => [
        const SizedBox(
          height: 240,
          child: StateView.empty(
            title: 'Belum ketemu',
            message: 'Coba tangkapan layar yang lebih jelas.',
          ),
        ),
        PictureButtons(
          onCamera: notifier.takePhoto,
          onFiles: notifier.pickFromGallery,
        ),
        QuotaNote(left: state.quotaLeft),
      ],
      SceneStatus.candidates => [
        ..._results(state, notifier, theme),
        QuotaNote(left: state.quotaLeft),
      ],
    };
  }

  Widget _working(String message) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.all(Spacing.xl),
      child: Column(
        spacing: Spacing.md,
        children: [
          Text(message, style: theme.textTheme.p),
          const ShadProgress(),
        ],
      ),
    );
  }

  Widget _failure(SceneSearchState state, SceneSearchNotifier notifier) {
    final error = state.error;
    return SizedBox(
      height: 360,
      child: error is BridgeError
          ? ErrorStateView(error: error, onRetry: notifier.retry)
          : StateView.error(
              title: 'Ada yang tidak beres',
              message: 'Pencarian gambar belum bisa dijalankan.',
              actionLabel: 'Coba lagi',
              onAction: notifier.retry,
            ),
    );
  }

  List<Widget> _results(
    SceneSearchState state,
    SceneSearchNotifier notifier,
    ShadThemeData theme,
  ) {
    final openError = state.openError;
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(
          Spacing.screenGutter,
          Spacing.sm,
          Spacing.screenGutter,
          Spacing.sm,
        ),
        child: Text('Mungkin ini adegannya', style: theme.textTheme.large),
      ),
      if (openError is BridgeError)
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.screenGutter,
            vertical: Spacing.sm,
          ),
          child: ShadAlert.destructive(
            description: Text(pesanError(openError)),
          ),
        ),
      for (final match in state.matches)
        SceneCandidateRow(
          match: match,
          best: match == state.best,
          onTap: () => notifier.choose(match),
        ),
    ];
  }
}
