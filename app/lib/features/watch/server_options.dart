import 'package:flutter/widgets.dart';

import '../../src/rust/dto/stream.dart';
import 'server_choice.dart';
import 'server_group.dart';

class ServerOptions extends StatelessWidget {
  const ServerOptions({
    super.key,
    required this.servers,
    required this.current,
    required this.onChoice,
    this.source,
    this.others = const [],
  });

  final List<ServerDto> servers;
  final String? current;
  final CurrentSource? source;
  final List<OtherSource> others;
  final ValueChanged<ServerChoice> onChoice;

  @override
  Widget build(BuildContext context) {
    final here = source;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (here != null)
          GroupHeading(
            title: here.label,
            note: here.summary,
            badge: others.isEmpty ? null : 'Sedang dipakai',
          ),
        if (here != null && here.audioOptions.isNotEmpty) ..._audio(here),
        if (here != null) const SubHeading('Server'),
        for (var i = 0; i < servers.length; i++)
          OptionRow(
            key: Key('server-option-${servers[i].id}'),
            label: serverLabel(servers, i),
            selected: servers[i].id == current,
            onTap: () => onChoice(PickServer(servers[i].id)),
          ),
        for (final other in others) ...[
          GroupHeading(title: other.label, note: other.summary),
          OptionRow(
            key: Key('source-option-${other.id}'),
            label: 'Putar dari sumber ini',
            hint: 'Episode yang sama, dengan server dari sumber ini',
            onTap: () => onChoice(UseSource(other.id)),
          ),
        ],
        if (others.isEmpty)
          OptionRow(
            key: const Key('other-source-option'),
            label: 'Coba sumber lain',
            hint: 'Dipakai bila semua server bermasalah',
            onTap: () => onChoice(const TryOtherSource()),
          ),
      ],
    );
  }

  List<Widget> _audio(CurrentSource here) => [
    const SubHeading('Suara'),
    OptionRow(
      key: const Key('audio-option-original'),
      label: 'Suara asli',
      selected: here.audio == null,
      onTap: () => onChoice(const PickAudio(null)),
    ),
    for (final label in here.audioOptions)
      OptionRow(
        key: Key('audio-option-$label'),
        label: label,
        selected: here.audio == label,
        onTap: () => onChoice(PickAudio(label)),
      ),
  ];
}
