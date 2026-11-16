import '../../src/rust/dto/stream.dart';

sealed class ServerChoice {
  const ServerChoice();
}

class PickServer extends ServerChoice {
  const PickServer(this.id);

  final String id;
}

class PickAudio extends ServerChoice {
  const PickAudio(this.label);

  final String? label;
}

class TryOtherSource extends ServerChoice {
  const TryOtherSource();
}

class UseSource extends ServerChoice {
  const UseSource(this.id);

  final String id;
}

typedef OtherSource = ({String id, String label, String? summary});

class CurrentSource {
  const CurrentSource({
    required this.label,
    this.summary,
    this.audioOptions = const [],
    this.audio,
  });

  final String label;
  final String? summary;
  final List<String> audioOptions;
  final String? audio;
}

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

String serverHint(List<ServerDto> servers) => hasVariants(servers)
    ? 'Sub: suara asli dengan teks terjemahan. Dub: suara diganti bahasa lain.'
    : 'Coba server lain bila video tidak mau berputar.';
