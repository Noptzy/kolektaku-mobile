import 'plan_guard.dart';

final _safeId = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

const _youtubeHosts = {
  'youtube.com',
  'youtube-nocookie.com',
  'ytimg.com',
  'kolektaku.mobile',
};
const _dailymotionHosts = {'dailymotion.com', 'dmcdn.net'};

String? trailerEmbedUrl(String site, String videoId) {
  if (!_safeId.hasMatch(videoId)) return null;
  return switch (site.toLowerCase()) {
    'youtube' =>
      'https://www.youtube-nocookie.com/embed/$videoId'
          '?autoplay=1&playsinline=1&rel=0&modestbranding=1',
    'dailymotion' =>
      'https://www.dailymotion.com/embed/video/$videoId?autoplay=1',
    _ => null,
  };
}

Map<String, String> trailerHeaders(String site) {
  return site.toLowerCase() == 'youtube'
      ? const {'Referer': 'https://www.youtube.com/'}
      : const {};
}

bool trailerNavigationAllowed(String site, Uri target) {
  if (target.scheme == 'about') return true;
  if (target.scheme != 'https') return false;
  final hosts = switch (site.toLowerCase()) {
    'youtube' => _youtubeHosts,
    'dailymotion' => _dailymotionHosts,
    _ => const <String>{},
  };
  return hosts.contains(registrableDomain(target.host));
}

const trailerErrorHandler = 'trailerError';
const youtubeOrigin = 'https://www.youtube.com';
const trailerAppOrigin = 'https://app.kolektaku.mobile';

String? youtubeWatchUrl(String videoId) =>
    _safeId.hasMatch(videoId) ? 'https://m.youtube.com/watch?v=$videoId' : null;

String? youtubePlayerHtml(String videoId) {
  if (!_safeId.hasMatch(videoId)) return null;
  return '''<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"><style>html,body{margin:0;height:100%;background:#000}#p{width:100%;height:100%}</style></head><body><div id="p"></div><script src="$youtubeOrigin/iframe_api"></script><script>function onYouTubeIframeAPIReady(){new YT.Player("p",{width:"100%",height:"100%",videoId:"$videoId",playerVars:{autoplay:1,playsinline:1,rel:0,modestbranding:1,origin:"$trailerAppOrigin"},events:{onReady:function(e){e.target.playVideo()},onError:function(e){window.flutter_inappwebview.callHandler("$trailerErrorHandler",e.data)}}})}</script></body></html>''';
}
