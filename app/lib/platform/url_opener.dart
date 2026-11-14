import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

abstract interface class UrlOpener {
  Future<bool> open(String url);
}

class SystemUrlOpener implements UrlOpener {
  const SystemUrlOpener();

  @override
  Future<bool> open(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

final urlOpenerProvider = Provider<UrlOpener>((ref) => const SystemUrlOpener());

String? trailerUrl(String site, String videoId) {
  return switch (site.toLowerCase()) {
    'youtube' => 'https://www.youtube.com/watch?v=$videoId',
    'dailymotion' => 'https://www.dailymotion.com/video/$videoId',
    _ => null,
  };
}
