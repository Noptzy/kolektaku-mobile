import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_text.dart';
import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/links.dart';
import '../../src/rust/dto/profile_facts.dart';
import '../detail/link_style.dart';
import 'profile_facts_logic.dart';

class ProfileDetails extends StatelessWidget {
  const ProfileDetails({
    super.key,
    required this.facts,
    required this.links,
    required this.onOpenLink,
  });

  final List<ProfileFactDto> facts;
  final List<ExternalLinkDto> links;
  final ValueChanged<String> onOpenLink;

  @override
  Widget build(BuildContext context) {
    final shown = shownLinks(links);
    if (facts.isEmpty && shown.isEmpty) return const SizedBox.shrink();
    final ink = ShadTheme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.screenGutter,
        vertical: Spacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Spacing.md,
        children: [
          if (facts.isNotEmpty) _FactsCard(facts: facts),
          if (shown.isNotEmpty)
            Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: [
                for (final link in shown)
                  ShadButton.outline(
                    key: Key('link-${link.url}'),
                    onPressed: () => onOpenLink(link.url),
                    leading: siteIcon(link.site, size: 16, color: ink),
                    child: Flexible(
                      child: Text(
                        linkLabel(link.site),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _FactsCard extends StatelessWidget {
  const _FactsCard({required this.facts});

  final List<ProfileFactDto> facts;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.card,
        borderRadius: Radii.cardShape,
        border: Border.all(color: scheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          spacing: Spacing.sm,
          children: [
            for (final fact in facts)
              Row(
                key: Key('fact-${fact.kind.name}'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 112,
                    child: Text(
                      factLabel(fact.kind),
                      style: theme.textTheme.cardMeta.copyWith(
                        color: scheme.mutedForeground,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      factValue(fact),
                      style: theme.textTheme.cardMeta.copyWith(
                        color: scheme.foreground,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
