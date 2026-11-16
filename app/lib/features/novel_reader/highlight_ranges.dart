typedef Marked = ({int id, int start, int end});

typedef Segment = ({int start, int end, int? highlightId});

Marked? locateMark({
  required int id,
  required String text,
  required int start,
  required int end,
  required String quote,
}) {
  if (quote.isEmpty) return null;
  final inPlace =
      start >= 0 &&
      end <= text.length &&
      start < end &&
      text.substring(start, end) == quote;
  if (inPlace) return (id: id, start: start, end: end);
  final moved = text.indexOf(quote);
  if (moved < 0) return null;
  return (id: id, start: moved, end: moved + quote.length);
}

List<Segment> segmentsOf(String text, List<Marked> marks) {
  final ordered = [...marks]..sort((a, b) => a.start.compareTo(b.start));
  final segments = <Segment>[];
  var cursor = 0;
  for (final mark in ordered) {
    final start = mark.start < cursor ? cursor : mark.start;
    if (mark.end <= start) continue;
    if (start > cursor) {
      segments.add((start: cursor, end: start, highlightId: null));
    }
    segments.add((start: start, end: mark.end, highlightId: mark.id));
    cursor = mark.end;
  }
  if (cursor < text.length) {
    segments.add((start: cursor, end: text.length, highlightId: null));
  }
  return segments;
}

({int start, int end})? rangeOfSelection(String text, String selected) {
  final wanted = selected.trim();
  if (wanted.isEmpty || wanted.contains('\n')) return null;
  final start = text.indexOf(wanted);
  if (start < 0) return null;
  return (start: start, end: start + wanted.length);
}

const maxHighlightChars = 1000;

bool isHighlightable(String selected) {
  final wanted = selected.trim();
  return wanted.isNotEmpty &&
      !wanted.contains('\n') &&
      wanted.length <= maxHighlightChars;
}
