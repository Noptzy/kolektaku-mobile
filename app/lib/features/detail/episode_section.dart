import 'package:flutter/services.dart'
    show FilteringTextInputFormatter, TextInputType;
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/library.dart';
import '../../src/rust/dto/media.dart';
import '../../src/rust/dto/sources.dart';
import 'episode_info_map.dart';
import 'episode_row.dart';
import 'episode_window.dart';

class EpisodeSection extends StatefulWidget {
  const EpisodeSection({
    super.key,
    required this.units,
    required this.kind,
    required this.progress,
    required this.descending,
    required this.onToggleOrder,
    required this.onOpen,
    this.focus,
    this.infos = const {},
    this.art,
  });

  final List<UnitDto> units;
  final MediaKindDto kind;
  final Map<double, ProgressDto> progress;
  final bool descending;
  final VoidCallback onToggleOrder;
  final ValueChanged<UnitDto> onOpen;
  final double? focus;
  final EpisodeInfos infos;
  final String? art;

  @override
  State<EpisodeSection> createState() => _EpisodeSectionState();
}

class _EpisodeSectionState extends State<EpisodeSection> {
  final TextEditingController _jump = TextEditingController();
  int _window = 0;
  double? _highlight;
  bool _missing = false;

  @override
  void initState() {
    super.initState();
    final focus = widget.focus;
    if (focus != null) {
      _window = windowIndexOf(_sorted, focus);
      _highlight = focus;
    }
  }

  @override
  void dispose() {
    _jump.dispose();
    super.dispose();
  }

  List<UnitDto> get _sorted =>
      sortedUnits(widget.units, descending: widget.descending);

  void _toJump() {
    final wanted = double.tryParse(_jump.text.trim().replaceAll(',', '.'));
    final sorted = _sorted;
    final at = wanted == null ? null : indexOfNumber(sorted, wanted);
    setState(() {
      _missing = at == null;
      if (at != null) {
        _window = at ~/ windowSize;
        _highlight = wanted;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sorted = _sorted;
    final windows = windowsFor(sorted.length);
    final index = _window.clamp(0, windows.isEmpty ? 0 : windows.length - 1);
    final slice = windows.isEmpty
        ? sorted
        : sorted.sublist(windows[index].start, windows[index].end);
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(child: _controls(sorted, windows, index)),
        SliverList.builder(
          itemCount: slice.length,
          itemBuilder: (context, position) {
            final unit = slice[position];
            return EpisodeRow(
              art: widget.art,
              unit: unit,
              kind: widget.kind,
              info: widget.infos[unit.number],
              progress: widget.progress[unit.number],
              highlighted: unit.number == _highlight,
              onTap: () => widget.onOpen(unit),
            );
          },
        ),
      ],
    );
  }

  Widget _controls(List<UnitDto> sorted, List<UnitWindow> windows, int index) {
    final theme = ShadTheme.of(context);
    final anime = widget.kind == MediaKindDto.anime;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.screenGutter,
        Spacing.md,
        Spacing.screenGutter,
        Spacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Spacing.md,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${sorted.length} ${anime ? 'episode' : 'chapter'}',
                  style: theme.textTheme.muted,
                ),
              ),
              ShadButton.ghost(
                onPressed: widget.onToggleOrder,
                size: ShadButtonSize.sm,
                leading: const Icon(LucideIcons.arrowUpDown, size: 16),
                child: Text(
                  widget.descending ? 'Terbaru dulu' : 'Terlama dulu',
                ),
              ),
            ],
          ),
          if (windows.isNotEmpty) ...[
            Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: [
                for (var i = 0; i < windows.length; i++)
                  ShadButton.raw(
                    variant: i == index
                        ? ShadButtonVariant.primary
                        : ShadButtonVariant.outline,
                    size: ShadButtonSize.sm,
                    onPressed: () => setState(() {
                      _window = i;
                      _highlight = null;
                    }),
                    child: Text(windows[i].label(sorted)),
                  ),
              ],
            ),
            Row(
              spacing: Spacing.sm,
              children: [
                Expanded(
                  child: ShadInput(
                    controller: _jump,
                    placeholder: Text(
                      'Lompat ke ${anime ? 'episode' : 'chapter'}',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    onSubmitted: (_) => _toJump(),
                  ),
                ),
                ShadButton.outline(
                  onPressed: _toJump,
                  child: const Text('Lompat'),
                ),
              ],
            ),
            if (_missing)
              Text(
                'Nomor itu tidak ada di daftar.',
                style: theme.textTheme.small.copyWith(
                  color: theme.colorScheme.destructive,
                ),
              ),
          ],
        ],
      ),
    );
  }
}
