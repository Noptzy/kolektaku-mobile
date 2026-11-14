import 'package:flutter/widgets.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/library.dart';
import '../../src/rust/dto/media.dart';
import '../../widgets/kind_switch.dart';
import '../../widgets/media_rail.dart';
import '../../widgets/option_chip.dart';
import 'home_actions.dart';
import 'resume_card.dart';

const _chipWidth = 72.0;

List<ProgressDto> resumeOf(List<ProgressDto> items, MediaKindDto? only) =>
    only == null
    ? items
    : [
        for (final item in items)
          if (item.kind == only) item,
      ];

class ResumeRail extends StatefulWidget {
  const ResumeRail({super.key, required this.items, required this.actions});

  final List<ProgressDto> items;
  final HomeActions actions;

  @override
  State<ResumeRail> createState() => _ResumeRailState();
}

class _ResumeRailState extends State<ResumeRail> {
  MediaKindDto? _only;

  void _toggle(MediaKindDto kind) =>
      setState(() => _only = _only == kind ? null : kind);

  @override
  Widget build(BuildContext context) {
    final shown = resumeOf(widget.items, _only);
    final cards = [for (final item in shown) resumeCard(item)];
    return MediaRail(
      title: 'Lanjutkan',
      cards: cards,
      progressOf: (card) => resumeFraction(shown[cards.indexOf(card)]),
      onTap: (card) => widget.actions.onResume(shown[cards.indexOf(card)]),
      trailing: Row(
        spacing: Spacing.sm,
        children: [
          for (final kind in MediaKindDto.values)
            SizedBox(
              width: _chipWidth,
              child: OptionChip(
                key: Key('resume-filter-${kind.name}'),
                label: kindSwitchLabel(kind),
                selected: _only == kind,
                dense: true,
                onTap: () => _toggle(kind),
              ),
            ),
        ],
      ),
    );
  }
}
