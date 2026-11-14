final _breaks = RegExp(r'<br\s*/?>', caseSensitive: false);
final _styling = RegExp(r'</?(?:b|i|strong|em|u|s)>', caseSensitive: false);
final _numeric = RegExp(r'&#(x[0-9a-fA-F]+|\d+);');
final _blank = RegExp(r'\n{3,}');
final _lineEnd = RegExp(r'[ \t]+\n');

const _named = {
  '&lt;': '<',
  '&gt;': '>',
  '&quot;': '"',
  '&apos;': "'",
  '&nbsp;': ' ',
};

String _codePoint(Match match) {
  final raw = match.group(1)!;
  final value = raw.startsWith('x')
      ? int.tryParse(raw.substring(1), radix: 16)
      : int.tryParse(raw);
  if (value == null || value <= 0 || value > 0x10FFFF) return match.group(0)!;
  return String.fromCharCode(value);
}

String plainText(String markup) {
  var text = markup.replaceAll(_breaks, '\n').replaceAll(_styling, '');
  text = text.replaceAllMapped(_numeric, _codePoint);
  _named.forEach((entity, character) {
    text = text.replaceAll(entity, character);
  });
  text = text.replaceAll('&amp;', '&');
  return text.replaceAll(_lineEnd, '\n').replaceAll(_blank, '\n\n').trim();
}
