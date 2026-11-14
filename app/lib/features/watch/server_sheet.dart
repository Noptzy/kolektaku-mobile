import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/stream.dart';
import '../../widgets/pressable.dart';

sealed class ServerChoice {
  const ServerChoice();
}

class PickServer extends ServerChoice {
  const PickServer(this.id);

  final String id;
}

class TryOtherSource extends ServerChoice {
  const TryOtherSource();
}

class UseSource extends ServerChoice {
  const UseSource(this.id);

  final String id;
}

typedef OtherSource = ({String id, String label, String? summary});

List<OtherSource> otherSourcesOf({
  required List<String> linked,
  required String? current,
  required Map<String, String> names,
  required Map<String, String> summaries,
}) {
  return [
    for (final id in linked)
      if (id != current && names.containsKey(id))
        (id: id, label: names[id]!, summary: summaries[id]),
  ];
}

String serverName(int index) => 'Server ${index + 1}';

String variantName(String variant) => variant == 'dub' ? 'Dub' : 'Sub';

String? audioName(String? code) => switch (code) {
  'ja' => 'Jepang',
  'en' => 'Inggris',
  'id' => 'Indonesia',
  _ => null,
};

String serverLabel(List<ServerDto> servers, int index) {
  final variant = servers[index].variant;
  if (variant == null) return serverName(index);
  final before = servers.take(index).where((s) => s.variant == variant).length;
  final base = 'Server ${before + 1} · ${variantName(variant)}';
  final audio = audioName(servers[index].audio);
  return audio == null ? base : '$base · audio $audio';
}

bool hasVariants(List<ServerDto> servers) =>
    servers.any((server) => server.variant != null);

Future<ServerChoice?> showServerSheet(
  BuildContext context, {
  required List<ServerDto> servers,
  required String? current,
  List<OtherSource> others = const [],
}) {
  return showShadSheet<ServerChoice>(
    context: context,
    side: ShadSheetSide.bottom,
    builder: (sheetContext) => ShadSheet(
      title: const Text('Ganti server'),
      description: Text(
        hasVariants(servers)
            ? 'Sub: suara asli dengan teks terjemahan. Dub: suara diganti '
                  'bahasa lain.'
            : 'Coba server lain bila video tidak mau berputar.',
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.md),
        child: Column(
          children: [
            for (var i = 0; i < servers.length; i++)
              _Row(
                keyName: 'server-option-${servers[i].id}',
                label: serverLabel(servers, i),
                selected: servers[i].id == current,
                onTap: () =>
                    Navigator.of(sheetContext).pop(PickServer(servers[i].id)),
              ),
            for (final other in others)
              _Row(
                keyName: 'source-option-${other.id}',
                label: other.label,
                hint: other.summary ?? 'Putar episode ini dari sumber lain',
                onTap: () =>
                    Navigator.of(sheetContext).pop(UseSource(other.id)),
              ),
            if (others.isEmpty)
              _Row(
                keyName: 'other-source-option',
                label: 'Coba sumber lain',
                hint: 'Dipakai bila semua server bermasalah',
                onTap: () =>
                    Navigator.of(sheetContext).pop(const TryOtherSource()),
              ),
          ],
        ),
      ),
    ),
  );
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
                    style: theme.textTheme.p.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (hint != null) Text(hint!, style: theme.textTheme.muted),
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
