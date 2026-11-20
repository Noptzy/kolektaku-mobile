import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/sources.dart';
import '../../widgets/pressable.dart';
import '../home/resume_card.dart';

String pickLabel(int count) =>
    count == 0 ? 'Pilih episode dulu' : 'Unduh $count episode';

class EpisodePicker extends StatefulWidget {
  const EpisodePicker({
    super.key,
    required this.units,
    required this.onConfirm,
    this.downloaded = const {},
  });

  final List<UnitDto> units;
  final Set<double> downloaded;
  final ValueChanged<List<UnitDto>> onConfirm;

  @override
  State<EpisodePicker> createState() => _EpisodePickerState();
}

class _EpisodePickerState extends State<EpisodePicker> {
  final Set<double> _chosen = {};

  List<UnitDto> get _open => [
    for (final unit in widget.units)
      if (!widget.downloaded.contains(unit.number)) unit,
  ];

  bool get _allChosen => _open.isNotEmpty && _chosen.length == _open.length;

  void _toggleAll() => setState(() {
    if (_allChosen) {
      _chosen.clear();
    } else {
      _chosen
        ..clear()
        ..addAll(_open.map((unit) => unit.number));
    }
  });

  void _toggle(double number) => setState(() {
    if (!_chosen.remove(number)) _chosen.add(number);
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final chosen = [
      for (final unit in widget.units)
        if (_chosen.contains(unit.number)) unit,
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Spacing.sm,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${_chosen.length} dari ${_open.length} dipilih',
                style: theme.textTheme.muted,
              ),
            ),
            ShadButton.ghost(
              key: const Key('pick-all'),
              size: ShadButtonSize.sm,
              onPressed: _toggleAll,
              child: Text(_allChosen ? 'Batal pilih' : 'Pilih semua'),
            ),
          ],
        ),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.45,
          ),
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 5,
            mainAxisSpacing: Spacing.sm,
            crossAxisSpacing: Spacing.sm,
            children: [
              for (final unit in widget.units)
                _EpisodeChip(
                  number: unit.number,
                  chosen: _chosen.contains(unit.number),
                  done: widget.downloaded.contains(unit.number),
                  onTap: () => _toggle(unit.number),
                ),
            ],
          ),
        ),
        ShadButton(
          key: const Key('pick-confirm'),
          onPressed: chosen.isEmpty ? null : () => widget.onConfirm(chosen),
          leading: const Icon(LucideIcons.download, size: 16),
          child: Text(pickLabel(chosen.length)),
        ),
      ],
    );
  }
}

class _EpisodeChip extends StatelessWidget {
  const _EpisodeChip({
    required this.number,
    required this.chosen,
    required this.done,
    required this.onTap,
  });

  final double number;
  final bool chosen;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    final fill = chosen ? scheme.primary : scheme.card;
    final ink = chosen ? scheme.primaryForeground : scheme.foreground;
    return Pressable(
      key: Key('pick-${unitText(number)}'),
      onTap: done ? null : onTap,
      label: 'Episode ${unitText(number)}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(Radii.poster - 4),
          border: Border.all(color: chosen ? scheme.primary : scheme.border),
        ),
        alignment: Alignment.center,
        child: done
            ? Icon(LucideIcons.check, size: 16, color: scheme.mutedForeground)
            : Text(
                unitText(number),
                style: TextStyle(color: ink, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}
