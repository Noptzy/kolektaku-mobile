import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../data/providers/source_providers.dart';
import '../../src/rust/dto/media.dart';
import '../../src/rust/dto/sources.dart';
import '../../widgets/poster.dart';
import '../../widgets/pressable.dart';

class MatchChoice {
  const MatchChoice.pick(this.source, this.item) : forget = false;

  const MatchChoice.forget() : source = null, item = null, forget = true;

  final String? source;
  final String? item;
  final bool forget;
}

Future<MatchChoice?> showWrongMatchSheet(
  BuildContext context, {
  required MediaKindDto kind,
  required String title,
  required String? currentSource,
  required bool hasManualChoice,
}) {
  return showShadSheet<MatchChoice>(
    context: context,
    side: ShadSheetSide.bottom,
    builder: (sheetContext) => ShadSheet(
      title: const Text('Bukan ini?'),
      description: const Text('Pilih judul yang benar dari sumber.'),
      child: WrongMatchBody(
        kind: kind,
        title: title,
        currentSource: currentSource,
        hasManualChoice: hasManualChoice,
        onChoice: (choice) => Navigator.of(sheetContext).pop(choice),
      ),
    ),
  );
}

class WrongMatchBody extends ConsumerStatefulWidget {
  const WrongMatchBody({
    super.key,
    required this.kind,
    required this.title,
    required this.currentSource,
    required this.hasManualChoice,
    required this.onChoice,
  });

  final MediaKindDto kind;
  final String title;
  final String? currentSource;
  final bool hasManualChoice;
  final ValueChanged<MatchChoice> onChoice;

  @override
  ConsumerState<WrongMatchBody> createState() => _WrongMatchBodyState();
}

class _WrongMatchBodyState extends ConsumerState<WrongMatchBody> {
  late final TextEditingController _query = TextEditingController(
    text: widget.title,
  );
  String? _source;
  late String _search = widget.title;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sources = ref.watch(enabledSourcesProvider(widget.kind));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.md),
      child: sources.when(
        loading: () => const Text('Memuat...'),
        error: (error, stack) => const Text('Sumber belum bisa dimuat.'),
        data: (items) => _content(context, items),
      ),
    );
  }

  Widget _content(BuildContext context, List<SourceStatusDto> items) {
    if (items.isEmpty) return const Text('Tidak ada sumber yang menyala.');
    final active = _source ?? widget.currentSource ?? items.first.id;
    final candidates = ref.watch(
      candidatesProvider((source: active, query: _search)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Spacing.md,
      children: [
        if (items.length > 1)
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: [
              for (var i = 0; i < items.length; i++)
                ShadButton.raw(
                  variant: items[i].id == active
                      ? ShadButtonVariant.primary
                      : ShadButtonVariant.outline,
                  size: ShadButtonSize.sm,
                  onPressed: () => setState(() => _source = items[i].id),
                  child: Text('Sumber ${i + 1}'),
                ),
            ],
          ),
        ShadInput(
          controller: _query,
          placeholder: const Text('Cari judul di sumber'),
          onSubmitted: (value) => setState(() => _search = value.trim()),
        ),
        candidates.when(
          loading: () => const Text('Mencari...'),
          error: (error, stack) =>
              const Text('Pencarian di sumber ini gagal. Coba sumber lain.'),
          data: (list) => _results(active, list),
        ),
        if (widget.hasManualChoice)
          ShadButton.ghost(
            onPressed: () => widget.onChoice(const MatchChoice.forget()),
            child: const Text('Lupakan pilihan saya'),
          ),
      ],
    );
  }

  Widget _results(String source, List<SourceItemDto> list) {
    if (list.isEmpty) return const Text('Tidak ada judul yang cocok.');
    final theme = ShadTheme.of(context);
    return Column(
      children: [
        for (final item in list.take(8))
          Pressable(
            onTap: () => widget.onChoice(MatchChoice.pick(source, item.item)),
            minSize: Sizes.touchTarget,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
              child: Row(
                spacing: Spacing.md,
                children: [
                  SizedBox(
                    width: 44,
                    child: Poster(url: item.coverUrl, radius: 6),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.p,
                        ),
                        if (item.latestLabel != null)
                          Text(item.latestLabel!, style: theme.textTheme.muted),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
