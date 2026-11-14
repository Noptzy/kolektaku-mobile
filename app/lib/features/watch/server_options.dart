import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/stream.dart';
import '../../widgets/pressable.dart';
import 'server_choice.dart';

class ServerOptions extends StatelessWidget {
  const ServerOptions({
    super.key,
    required this.servers,
    required this.current,
    required this.onChoice,
    this.others = const [],
  });

  final List<ServerDto> servers;
  final String? current;
  final List<OtherSource> others;
  final ValueChanged<ServerChoice> onChoice;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < servers.length; i++)
          _Row(
            keyName: 'server-option-${servers[i].id}',
            label: serverLabel(servers, i),
            selected: servers[i].id == current,
            onTap: () => onChoice(PickServer(servers[i].id)),
          ),
        for (final other in others)
          _Row(
            keyName: 'source-option-${other.id}',
            label: other.label,
            hint: other.summary ?? 'Putar episode ini dari sumber lain',
            onTap: () => onChoice(UseSource(other.id)),
          ),
        if (others.isEmpty)
          _Row(
            keyName: 'other-source-option',
            label: 'Coba sumber lain',
            hint: 'Dipakai bila semua server bermasalah',
            onTap: () => onChoice(const TryOtherSource()),
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.keyName,
    required this.label,
    required this.onTap,
    this.hint,
    this.selected = false,
  });

  final String keyName;
  final String label;
  final String? hint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Pressable(
      key: Key(keyName),
      onTap: onTap,
      selected: selected,
      minSize: Sizes.touchTarget,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.small.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (hint != null)
                    Text(
                      hint!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.muted.copyWith(fontSize: 12),
                    ),
                ],
              ),
            ),
            if (selected)
              Icon(
                LucideIcons.check,
                size: 20,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}
