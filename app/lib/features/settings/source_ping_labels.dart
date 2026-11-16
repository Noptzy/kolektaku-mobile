import '../../src/rust/dto/sources.dart';

enum PingTone { good, warning, bad }

typedef PingReading = ({String text, PingTone tone});

String _took(int millis) {
  if (millis < 1000) return '$millis ms';
  final seconds = (millis / 1000).toStringAsFixed(1).replaceAll('.', ',');
  return '$seconds dtk';
}

PingReading pingReading(SourcePingDto result) {
  return switch (result.verdict) {
    PingVerdictDto.online => (
      text: 'Aktif · ${_took(result.millis)}',
      tone: PingTone.good,
    ),
    PingVerdictDto.changed => (
      text: 'Merespons, tapi tampilannya berubah',
      tone: PingTone.warning,
    ),
    PingVerdictDto.offline => (
      text: 'Tidak bisa dijangkau',
      tone: PingTone.bad,
    ),
  };
}
