import '../../src/rust/dto/scene.dart';
import '../home/resume_card.dart';

String momentLabel(double seconds) {
  final total = seconds.isNaN || seconds < 0 ? 0 : seconds.round();
  final hours = total ~/ 3600;
  final minutes = (total % 3600) ~/ 60;
  final rest = total % 60;
  String two(int value) => value.toString().padLeft(2, '0');
  return hours > 0
      ? '$hours:${two(minutes)}:${two(rest)}'
      : '${two(minutes)}:${two(rest)}';
}

String episodeMoment(SceneMatchDto match) {
  final episode = match.episode;
  final moment = momentLabel(match.atSecs);
  return episode == null ? moment : 'Ep ${unitText(episode)} · $moment';
}

String similarityLabel(double similarity) => '${(similarity * 100).round()}%';

String quotaLabel(int left) => 'Sisa pencarian gambar hari ini: $left';
