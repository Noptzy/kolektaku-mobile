import '../../src/rust/dto/downloads.dart';
import '../home/resume_card.dart';

const _active = {
  DownloadPhaseDto.queued,
  DownloadPhaseDto.fetching,
  DownloadPhaseDto.subtitles,
  DownloadPhaseDto.muxing,
};

bool isActive(DownloadDto job) => _active.contains(job.phase);

bool canRetry(DownloadDto job) =>
    job.phase == DownloadPhaseDto.failed ||
    job.phase == DownloadPhaseDto.cancelled;

List<DownloadDto> activeOf(List<DownloadDto> jobs) => [
  for (final job in jobs)
    if (isActive(job)) job,
];

double? overallProgress(List<DownloadDto> jobs) {
  final active = activeOf(jobs);
  if (active.isEmpty) return null;
  final sum = active.fold<double>(0, (total, job) => total + job.progress);
  return (sum / active.length).clamp(0.0, 1.0);
}

String percent(double fraction) => '${(fraction * 100).round()}%';

String phaseLabel(DownloadDto job) => switch (job.phase) {
  DownloadPhaseDto.queued => 'Menunggu giliran',
  DownloadPhaseDto.fetching => 'Mengunduh ${percent(job.progress)}',
  DownloadPhaseDto.subtitles => 'Menyiapkan subtitle',
  DownloadPhaseDto.muxing => 'Menyatukan video ${percent(job.progress)}',
  DownloadPhaseDto.done => 'Selesai',
  DownloadPhaseDto.failed =>
    job.interrupted ? 'Terhenti saat aplikasi ditutup' : 'Gagal mengunduh',
  DownloadPhaseDto.cancelled => 'Dibatalkan',
};

String sizeLabel(BigInt bytes) {
  final value = bytes.toDouble();
  if (value < 1024 * 1024) return '${(value / 1024).toStringAsFixed(0)} KB';
  final megabytes = value / (1024 * 1024);
  if (megabytes < 1024) {
    return '${megabytes.toStringAsFixed(1).replaceAll('.', ',')} MB';
  }
  final gigabytes = megabytes / 1024;
  return '${gigabytes.toStringAsFixed(2).replaceAll('.', ',')} GB';
}

String episodeLabel(DownloadTargetDto target) =>
    'Episode ${unitText(target.episode)}';

bool needsExport(DownloadDto job) {
  final path = job.filePath;
  return job.phase == DownloadPhaseDto.done &&
      path != null &&
      !path.startsWith('content://');
}

String fileNameOf(DownloadDto job) {
  final path = job.filePath ?? '';
  final slash = path.lastIndexOf('/');
  final name = slash < 0 ? path : path.substring(slash + 1);
  return name.isEmpty
      ? '${job.target.title} ${episodeLabel(job.target)}.mkv'
      : name;
}

String notificationTitle(List<DownloadDto> jobs) {
  final active = activeOf(jobs);
  return active.length == 1
      ? '${active.first.target.title} · ${episodeLabel(active.first.target)}'
      : 'Mengunduh ${active.length} episode';
}

String notificationText(List<DownloadDto> jobs) {
  final progress = overallProgress(jobs);
  if (progress == null) return '';
  final working = activeOf(jobs)
      .where((job) => job.phase != DownloadPhaseDto.queued);
  final phase = working.isEmpty
      ? 'Menunggu giliran'
      : phaseLabel(working.first);
  return '$phase · total ${percent(progress)}';
}
