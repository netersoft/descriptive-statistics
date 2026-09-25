import 'dart:math' as math;

import '../tools/functions/number_parsing.dart';

/// What's wrong with a raw series, or with the classes asked for it.
enum RawSeriesError {
  /// [RawSeriesException.token] isn't a number.
  invalidValue,

  /// The class start the user typed ([RawSeriesException.token]) isn't a
  /// number.
  invalidStart,

  /// The class width the user typed isn't a number above zero.
  invalidWidth,

  /// The smallest value ([RawSeriesException.token], as typed) falls below
  /// the class start.
  startAboveMin,

  /// The classes would outnumber [maxClasses] ([RawSeriesException.token]).
  tooManyClasses,
}

/// Thrown when a raw series can't be tallied -- [token] is the offending
/// piece, to show the user.
class RawSeriesException implements Exception {
  final String token;
  final RawSeriesError error;

  const RawSeriesException(this.token, [this.error = RawSeriesError.invalidValue]);

  @override
  String toString() => 'RawSeriesException(${error.name}, $token)';
}

/// More classes than this is almost certainly a width typed wrong, and
/// would make an unreadable table.
const maxClasses = 100;

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
  for (final (:value, token: _) in _parseNumericSeries(text)) {
    counts[value] = (counts[value] ?? 0) + 1;
  }
  final values = counts.keys.toList()..sort();
  return [for (final value in values) (value: value, count: counts[value]!)];
}

/// Groups a raw numeric series into classes of equal [width] (text as the
/// user typed it) starting at [start], and counts the values in each --
/// the L1/L2/Ni table of the continuous calculator, ascending, empty
/// classes included so the classes stay contiguous.
///
/// Classes are closed on the left and open on the right, [L1 ; L2[: a
/// value equal to a bound goes into the class that starts there.
///
/// [start] and [width] left blank are chosen automatically (see
/// [suggestClasses]). Throws [RawSeriesException] on a bad value, start or
/// width, a start above the smallest value, or more than [maxClasses]
/// classes.
List<({double lower, double upper, int count})> groupContinuousSeries(String text, {String start = '', String width = ''}) {
  final series = _parseNumericSeries(text);
  if (series.isEmpty) return const [];

  final values = [for (final (:value, token: _) in series) value];
  final suggested = suggestClasses(values);

  final classWidth = width.trim().isEmpty ? suggested.width : parseDecimal(width);
  if (classWidth == null || classWidth <= 0 || !classWidth.isFinite) {
    throw RawSeriesException(width.trim(), RawSeriesError.invalidWidth);
  }
  final classStart = start.trim().isEmpty ? _floorTo(values.reduce(math.min), classWidth) : parseDecimal(start);
  if (classStart == null || !classStart.isFinite) throw RawSeriesException(start.trim(), RawSeriesError.invalidStart);

  final smallest = series.reduce((a, b) => b.value < a.value ? b : a);
  if (smallest.value < classStart) throw RawSeriesException(smallest.token, RawSeriesError.startAboveMin);

  final counts = <int, int>{};
  for (final value in values) {
    final index = _classIndex(value, classStart, classWidth);
    counts[index] = (counts[index] ?? 0) + 1;
  }
  final classCount = counts.keys.reduce(math.max) + 1;
  if (classCount > maxClasses) throw const RawSeriesException('$maxClasses', RawSeriesError.tooManyClasses);

  return [
    for (var i = 0; i < classCount; i++)
      (
        lower: _clean(classStart + i * classWidth),
        upper: _clean(classStart + (i + 1) * classWidth),
        count: counts[i] ?? 0,
      ),
  ];
}

/// A starting point for grouping [values] into classes: Sturges' rule
/// (1 + log2(n) classes, rounded up) spread over the range, with the width
/// rounded up to a readable 1, 2, 2.5 or 5 times a power of ten, and the
/// start rounded down to a multiple of that width.
({double start, double width}) suggestClasses(List<double> values) {
  final smallest = values.reduce(math.min);
  final range = values.reduce(math.max) - smallest;
  final classes = (1 + math.log(values.length) / math.ln2).ceil();
  final width = range == 0 ? 1.0 : _niceCeil(range / classes);
  return (start: _floorTo(smallest, width), width: width);
}

/// Which class (0 for the one starting at [start]) holds [value]. The
/// epsilon keeps a value sitting on a bound -- which floating point may
/// divide to 2.9999999999999996 -- in the class that starts there.
int _classIndex(double value, double start, double width) => ((value - start) / width + 1e-9).floor();

double _floorTo(double value, double step) => _clean(((value / step) + 1e-9).floorToDouble() * step);

/// The smallest of 1, 2, 2.5 and 5 times a power of ten that is >= [value].
double _niceCeil(double value) {
  final magnitude = math.pow(10, (math.log(value) / math.ln10).floor()).toDouble();
  for (final factor in const [1, 2, 2.5, 5]) {
    if (factor * magnitude >= value * (1 - 1e-12)) return _clean(factor * magnitude);
  }
  return _clean(10 * magnitude);
}

/// Drops floating-point noise from a computed bound (0.30000000000000004).
double _clean(double value) => double.parse(value.toStringAsPrecision(12));

/// Splits a raw numeric series into its values, keeping each one's text as
/// typed. Throws [RawSeriesException] on a token that isn't a number.
List<({double value, String token})> _parseNumericSeries(String text) => [
  for (final token in text.trim().split(_numericSeparator))
    if (token.isNotEmpty) (value: parseDecimal(token) ?? (throw RawSeriesException(token)), token: token),
];

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
