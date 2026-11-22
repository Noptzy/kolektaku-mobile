import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_text.dart';
import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/cards.dart';
import '../../src/rust/dto/media.dart';
import '../../widgets/top10_rail.dart';
import 'top10_switch.dart';

const top10Title = 'Top 10 hari ini';

class Top10Section extends StatefulWidget {
  const Top10Section({super.key, required this.cards, required this.onTap});

  final Map<MediaKindDto, List<MediaCardDto>> cards;
  final void Function(MediaKindDto kind, MediaCardDto card) onTap;

  @override
  State<Top10Section> createState() => _Top10SectionState();
}

class _Top10SectionState extends State<Top10Section> {
  MediaKindDto? _picked;

  List<MediaKindDto> get _kinds => [
    for (final entry in widget.cards.entries)
      if (entry.value.isNotEmpty) entry.key,
  ];

  MediaKindDto? get _shown {
    final kinds = _kinds;
    if (kinds.isEmpty) return null;
    return kinds.contains(_picked) ? _picked : kinds.first;
  }

  @override
  Widget build(BuildContext context) {
    final shown = _shown;
    if (shown == null) return const SizedBox.shrink();
    final kinds = _kinds;
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.screenGutter),
          child: Row(
            children: [
              Expanded(
                child: Text(top10Title, style: theme.textTheme.sectionTitle),
              ),
              if (kinds.length > 1)
                Top10Switch(
                  kinds: kinds,
                  selected: shown,
                  onChanged: (kind) => setState(() => _picked = kind),
                ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.md),
        AnimatedSwitcher(
          duration: Motion.quick,
          child: Top10List(
            key: ValueKey(shown),
            cards: widget.cards[shown]!,
            onTap: (card) => widget.onTap(shown, card),
          ),
        ),
      ],
    );
  }
}
