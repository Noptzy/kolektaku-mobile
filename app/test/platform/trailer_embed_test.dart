import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/platform/trailer_embed.dart';

void main() {
  group('trailerEmbedUrl', () {
    test('a video starts by itself inside the page', () {
      final url = trailerEmbedUrl('youtube', 'abc_123-X')!;
      expect(
        url,
        startsWith('https://www.youtube-nocookie.com/embed/abc_123-X'),
      );
      expect(url, contains('autoplay=1'));
      expect(url, contains('playsinline=1'));
    });

    test('the site name is not case sensitive', () {
      expect(trailerEmbedUrl('YouTube', 'abc'), isNotNull);
      expect(
        trailerEmbedUrl('Dailymotion', 'x8abc'),
        'https://www.dailymotion.com/embed/video/x8abc?autoplay=1',
      );
    });

    test('unknown sites have no embed', () {
      expect(trailerEmbedUrl('vimeo', 'abc'), isNull);
      expect(trailerEmbedUrl('', 'abc'), isNull);
    });

    test('an id that could escape the address is refused', () {
      expect(trailerEmbedUrl('youtube', 'a/../b'), isNull);
      expect(trailerEmbedUrl('youtube', 'a?b=1'), isNull);
      expect(trailerEmbedUrl('youtube', 'a"><script>'), isNull);
      expect(trailerEmbedUrl('youtube', ''), isNull);
      expect(trailerEmbedUrl('youtube', 'a' * 65), isNull);
    });
  });

  group('trailerHeaders', () {
    test('youtube gets a referer and others none', () {
      expect(trailerHeaders('youtube'), {
        'Referer': 'https://www.youtube.com/',
      });
      expect(trailerHeaders('dailymotion'), isEmpty);
    });
  });

  group('trailerNavigationAllowed', () {
    test('stays on the video site of the trailer', () {
      expect(
        trailerNavigationAllowed(
          'youtube',
          Uri.parse('https://www.youtube.com/embed/abc'),
        ),
        isTrue,
      );
      expect(
        trailerNavigationAllowed(
          'youtube',
          Uri.parse('https://www.youtube-nocookie.com/embed/abc'),
        ),
        isTrue,
      );
      expect(
        trailerNavigationAllowed(
          'dailymotion',
          Uri.parse('https://geo.dailymotion.com/player.html'),
        ),
        isTrue,
      );
    });

    test('other sites, other sites’ hosts and plain http are refused', () {
      expect(
        trailerNavigationAllowed(
          'youtube',
          Uri.parse('https://ads.example.com/'),
        ),
        isFalse,
      );
      expect(
        trailerNavigationAllowed(
          'youtube',
          Uri.parse('https://www.dailymotion.com/video/x'),
        ),
        isFalse,
      );
      expect(
        trailerNavigationAllowed(
          'youtube',
          Uri.parse('http://www.youtube.com/'),
        ),
        isFalse,
      );
      expect(
        trailerNavigationAllowed(
          'youtube',
          Uri.parse('https://youtube.com.evil.test/'),
        ),
        isFalse,
      );
      expect(
        trailerNavigationAllowed('vimeo', Uri.parse('https://vimeo.com/1')),
        isFalse,
      );
    });

    test('blank frames are allowed', () {
      expect(
        trailerNavigationAllowed('youtube', Uri.parse('about:blank')),
        isTrue,
      );
    });
  });

  group('youtubePlayerHtml', () {
    test('loads the player api and starts the video', () {
      final html = youtubePlayerHtml('abc_123-X')!;
      expect(html, contains('https://www.youtube.com/iframe_api'));
      expect(html, contains('videoId:"abc_123-X"'));
      expect(html, contains('autoplay:1'));
      expect(html, contains('origin:"$trailerAppOrigin"'));
      expect(html, contains('playsinline:1'));
    });

    test('a failure inside the player is reported to the app', () {
      final html = youtubePlayerHtml('abc')!;
      expect(html, contains('onError'));
      expect(html, contains('callHandler("$trailerErrorHandler"'));
    });

    test('an id that could break out of the page is refused', () {
      expect(youtubePlayerHtml('a"+alert(1)+"'), isNull);
      expect(youtubePlayerHtml('a b'), isNull);
      expect(youtubePlayerHtml(''), isNull);
      expect(youtubePlayerHtml('a' * 65), isNull);
    });
  });

  group('the fallback watch page', () {
    test('is the mobile watch page of the same video', () {
      expect(
        youtubeWatchUrl('abc_123-X'),
        'https://m.youtube.com/watch?v=abc_123-X',
      );
    });

    test('is refused for an id that could break out', () {
      expect(youtubeWatchUrl('a b'), isNull);
      expect(youtubeWatchUrl('a&b=1'), isNull);
      expect(youtubeWatchUrl(''), isNull);
    });

    test('can be opened inside the trailer view', () {
      final watch = Uri.parse(youtubeWatchUrl('abc')!);
      expect(trailerNavigationAllowed('youtube', watch), isTrue);
    });

    test('the page the app loads for the player is allowed too', () {
      expect(
        trailerNavigationAllowed('youtube', Uri.parse(trailerAppOrigin)),
        isTrue,
      );
      expect(
        trailerNavigationAllowed('dailymotion', Uri.parse(trailerAppOrigin)),
        isFalse,
      );
    });

    test('the app never identifies itself as the video site', () {
      expect(trailerAppOrigin, isNot(contains('youtube')));
    });
  });
}
