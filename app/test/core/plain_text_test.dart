import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/plain_text.dart';

void main() {
  group('plainText', () {
    test('breaks become new lines', () {
      expect(plainText('a<br>b<br/>c<BR />d'), 'a\nb\nc\nd');
    });

    test('a paragraph break stays as one blank line', () {
      expect(plainText('a<br><br>b'), 'a\n\nb');
      expect(plainText('a<br><br><br><br>b'), 'a\n\nb');
    });

    test('bold and italic marks disappear but their words stay', () {
      expect(plainText('<b>Tinggi:</b> 153 <i>cm</i>'), 'Tinggi: 153 cm');
      expect(plainText('<strong>x</strong><em>y</em>'), 'xy');
    });

    test('entities turn back into characters', () {
      expect(plainText('5 &lt; 6 &amp; 7 &gt; 2'), '5 < 6 & 7 > 2');
      expect(plainText('&quot;hai&quot; &#39;dunia&#39;'), '"hai" \'dunia\'');
      expect(plainText('a&nbsp;b'), 'a b');
      expect(plainText('&#x2764;'), '❤');
    });

    test('an escaped entity is decoded once only', () {
      expect(plainText('&amp;lt;'), '&lt;');
    });

    test('broken or huge numbers are left alone', () {
      expect(plainText('&#99999999;'), '&#99999999;');
      expect(plainText('&#0;'), '&#0;');
    });

    test('edges are trimmed and trailing spaces dropped', () {
      expect(plainText('<br>a  <br>b<br>'), 'a\nb');
    });

    test('plain text passes through and empty stays empty', () {
      expect(plainText('君の名は。'), '君の名は。');
      expect(plainText(''), '');
    });
  });
}
