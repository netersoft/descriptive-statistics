import '../tools/functions/number_parsing.dart';

/// Thrown when a raw series contains something that isn't a value --
/// [token] is the offending piece, to show the user.
class RawSeriesException implements Exception {
  final String token;

  const RawSeriesException(this.token);

  @override
  String toString() => 'RawSeriesException($token)';
}

/// Numeric values are separated by whitespace, semicolons, or a comma
/// followed by whitespace ("3, 5, 5"). A comma directly between digits is
/// a decimal separator ("2,5"), as in fr/de/es/pt -- so "3,5,5" is
/// ambiguous and rejected rather than guessed at.
final _numericSeparator = RegExp(r',?[\s;]+');

/// Modality names may contain spaces ("Très bien"), so only line breaks,
/// semicolons and commas separate them.
final _qualitativeSeparator = RegExp(r'[\n;,]+');

/// Counts how many times each value occurs in a raw numeric series
/// ("3 5 5 7 3"), ascending by value -- the Xi/Ni table the student would
/// otherwise build by hand. Throws [RawSeriesException] on a token that
/// isn't a number.
List<({double value, int count})> tallyNumericSeries(String text) {
  final counts = <double, int>{};
  for (final token in text.trim().split(_numericSeparator)) {
    if (token.isEmpty) continue;
    final value = parseDecimal(token);
    if (value == null) throw RawSeriesException(token);
    counts[value] = (counts[value] ?? 0) + 1;
  }
  final values = counts.keys.toList()..sort();
  return [for (final value in values) (value: value, count: counts[value]!)];
}

/// Counts how many times each modality occurs in a raw qualitative series
/// ("Rouge; Bleu; Rouge"), in first-seen order. Surrounding spaces are
/// ignored; matching is otherwise exact (case-sensitive).
List<({String value, int count})> tallyQualitativeSeries(String text) {
  final counts = <String, int>{};
  for (final token in text.split(_qualitativeSeparator)) {
    final modality = token.trim();
    if (modality.isEmpty) continue;
    counts[modality] = (counts[modality] ?? 0) + 1;
  }
  return [for (final entry in counts.entries) (value: entry.key, count: entry.value)];
}
