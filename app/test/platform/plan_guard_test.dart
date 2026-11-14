import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/platform/plan_guard.dart';

void main() {
  group('checkedPlanUrl', () {
    test('accepts a secure address on exactly the allowed host', () {
      final uri = checkedPlanUrl(
        url: 'https://v20.site.example/anime/1/x/episode/2',
        allowedHost: 'v20.site.example',
      );
      expect(uri.host, 'v20.site.example');
    });

    test('rejects other hosts, plain http and nonsense', () {
      for (final url in [
        'https://evil.example/anime/1',
        'http://v20.site.example/anime/1',
        'not a url',
        'https:///path',
        'javascript:alert(1)',
      ]) {
        expect(
          () => checkedPlanUrl(url: url, allowedHost: 'v20.site.example'),
          throwsA(isA<PlanRejected>()),
          reason: url,
        );
      }
    });

    test('host comparison ignores case', () {
      expect(
        () => checkedPlanUrl(
          url: 'https://V20.Site.Example/x',
          allowedHost: 'v20.site.example',
        ),
        returnsNormally,
      );
    });
  });

  group('navigationAllowed', () {
    const host = 'v20.site.example';
    bool allowed(String url) =>
        navigationAllowed(target: Uri.parse(url), allowedHost: host);

    test('stays within the same site, including a newer subdomain', () {
      expect(allowed('https://v20.site.example/next'), isTrue);
      expect(allowed('https://v21.site.example/next'), isTrue);
      expect(allowed('https://site.example/'), isTrue);
    });

    test('blocks other sites, lookalikes and non-secure schemes', () {
      expect(allowed('https://evil.example/'), isFalse);
      expect(allowed('https://site.example.evil.test/'), isFalse);
      expect(allowed('https://notsite.example/'), isFalse);
      expect(allowed('http://v20.site.example/'), isFalse);
      expect(allowed('intent://x'), isFalse);
    });

    test('the blank page is always fine', () {
      expect(allowed('about:blank'), isTrue);
    });
  });
}
