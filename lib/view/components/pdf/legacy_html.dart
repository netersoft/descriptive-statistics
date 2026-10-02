import 'dart:math' as math;

/// A run of text sharing one style, from the app's legacy-style HTML.
class HtmlRun {
  final String text;
  final bool bold;
  final bool italic;
  final bool underline;

  /// The `<font color>` value as written ("red", "#64B5F6"), or null.
  final String? color;

  const HtmlRun(this.text, {this.bold = false, this.italic = false, this.underline = false, this.color});

  @override
  bool operator ==(Object other) =>
      other is HtmlRun && other.text == text && other.bold == bold && other.italic == italic && other.underline == underline && other.color == color;

  @override
  int get hashCode => Object.hash(text, bold, italic, underline, color);

  @override
  String toString() => 'HtmlRun(${[text, if (bold) 'b', if (italic) 'i', if (underline) 'u', ?color].join(', ')})';
}

final _token = RegExp(r'<(/?)(\w+)([^>]*)>|([^<]+)');
final _colorAttribute = RegExp(r'''color\s*=\s*(['"]?)([#\w]+)\1''', caseSensitive: false);
final _entity = RegExp(r'&(#\d+|#x[0-9a-fA-F]+|\w+);');

const _entities = {
  'sum': '∑',
  'sigma': 'σ',
  'radic': '√',
  'sup2': '²',
  'amp': '&',
  'lt': '<',
  'gt': '>',
  'quot': '"',
  'apos': "'",
  'nbsp': ' ',
};

/// Splits the HTML the explanations and backups are written in into lines
/// (one per `<br>`) of styled runs. Only what that HTML uses is supported:
/// `<b>`, `<i>`, `<u>`, `<font color>` and `<br>`; any other tag is
/// dropped, keeping its text. Whitespace collapses as in a browser, so
/// the source's own line breaks and tabs don't show.
List<List<HtmlRun>> parseLegacyHtml(String html) {
  final lines = <List<HtmlRun>>[[]];
  var bold = 0;
  var italic = 0;
  var underline = 0;
  // A <font> without a color keeps the current one, but still gets closed
  // by its </font>, so it is pushed too.
  final colors = <String?>[];

  for (final match in _token.allMatches(html)) {
    final text = match[4];
    if (text != null) {
      final decoded = _decodeEntities(text.replaceAll(RegExp(r'\s+'), ' '));
      final line = lines.last;
      // A line starts after a <br>, where a browser drops leading spaces.
      final trimmed = line.isEmpty || line.last.text.endsWith(' ') ? decoded.trimLeft() : decoded;
      if (trimmed.isEmpty) continue;
      line.add(HtmlRun(trimmed, bold: bold > 0, italic: italic > 0, underline: underline > 0, color: colors.lastOrNull));
      continue;
    }

    final closing = match[1] == '/';
    final delta = closing ? -1 : 1;
    switch (match[2]!.toLowerCase()) {
      case 'br':
        lines.add([]);
      case 'b' || 'strong':
        bold = math.max(0, bold + delta);
      case 'i' || 'em':
        italic = math.max(0, italic + delta);
      case 'u':
        underline = math.max(0, underline + delta);
      case 'font' when closing:
        if (colors.isNotEmpty) colors.removeLast();
      case 'font':
        colors.add(_colorAttribute.firstMatch(match[3]!)?[2] ?? colors.lastOrNull);
    }
  }

  // Spaces before a <br> don't show either.
  for (final line in lines) {
    if (line.isNotEmpty && line.last.text.endsWith(' ')) {
      final last = line.removeLast();
      final text = last.text.trimRight();
      if (text.isNotEmpty) {
        line.add(HtmlRun(text, bold: last.bold, italic: last.italic, underline: last.underline, color: last.color));
      }
    }
  }
  return lines;
}

String _decodeEntities(String text) => text.replaceAllMapped(_entity, (match) {
  final name = match[1]!;
  if (name.startsWith('#x')) return String.fromCharCode(int.parse(name.substring(2), radix: 16));
  if (name.startsWith('#')) return String.fromCharCode(int.parse(name.substring(1)));
  return _entities[name] ?? match[0]!;
});
