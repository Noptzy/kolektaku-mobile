import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/detail/link_style.dart';
import 'package:kolektaku/src/rust/dto/links.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

ExternalLinkDto link(String site, String url) =>
    ExternalLinkDto(site: site, url: url, kind: 'SOCIAL');

void main() {
  group('linkLabel', () {
    test('the official site is named in Indonesian', () {
      expect(linkLabel('Official Site'), 'Situs resmi');
      expect(linkLabel(' official site '), 'Situs resmi');
    });

    test('X is still called Twitter and other sites keep their name', () {
      expect(linkLabel('X'), 'Twitter');
      expect(linkLabel('Instagram'), 'Instagram');
      expect(linkLabel('Mastodon'), 'Mastodon');
    });
  });

  group('linkIcon', () {
    test('known sites have their own icon, ignoring case', () {
      expect(linkIcon('Official Site'), LucideIcons.globe);
      expect(linkIcon('TWITTER'), linkIcon('x'));
      expect(linkIcon('Instagram'), isNot(linkIcon('Twitter')));
      expect(linkIcon('TikTok'), LucideIcons.music);
    });

    test('an unknown site gets the plain link icon', () {
      expect(linkIcon('Mastodon'), LucideIcons.link);
      expect(linkIcon(''), LucideIcons.link);
    });
  });

  group('openableLink', () {
    test('only secure web addresses can be opened', () {
      expect(openableLink('https://a.test/x'), isTrue);
      expect(openableLink('http://a.test/x'), isFalse);
      expect(openableLink('javascript:alert(1)'), isFalse);
      expect(openableLink('file:///etc/passwd'), isFalse);
      expect(openableLink('intent://x#Intent;end'), isFalse);
      expect(openableLink('/relative'), isFalse);
      expect(openableLink('https://'), isFalse);
      expect(openableLink(''), isFalse);
    });
  });

  group('shownLinks', () {
    test('unsafe and repeated addresses are dropped, order is kept', () {
      final shown = shownLinks([
        link('Official Site', 'https://a.test/'),
        link('Bad', 'javascript:alert(1)'),
        link('Twitter', 'https://twitter.com/a'),
        link('Again', 'https://twitter.com/a'),
      ]);
      expect(shown.map((item) => item.site), ['Official Site', 'Twitter']);
    });

    test('no more than a handful are shown', () {
      final many = [
        for (var i = 0; i < 20; i++) link('S$i', 'https://s$i.test/'),
      ];
      expect(shownLinks(many).length, maxShownLinks);
      expect(shownLinks(many).first.site, 'S0');
    });

    test('nothing in, nothing out', () {
      expect(shownLinks(const []), isEmpty);
    });
  });
}
