import 'dart:math' as math;

/// Rounds [value] to [decimals] decimal places, half away from zero.
///
/// Mirrors the legacy Android app's `arrondi()`, which cast
/// `(int) (value * 10^decimals + 0.5)` -- that truncates toward zero, so it
/// rounds negative halves the wrong way (e.g. -2.45 would become -2.4
/// instead of -2.5). This applies the same half-up rule symmetrically for
/// negative values instead of blindly porting that bug.
double arrondi(double value, int decimals) {
  final factor = math.pow(10, decimals).toDouble();
  final rounded = (value.abs() * factor + 0.5).truncateToDouble();
  return (value.isNegative ? -rounded : rounded) / factor;
}

/// Formats [value] without a trailing ".0" for whole numbers, matching the
/// legacy app's `noZero()`.
String noZero(double value) {
  final text = value.toString();
  final dotIndex = text.indexOf('.');
  if (dotIndex != -1 && text.substring(dotIndex + 1) == '0') {
    return text.substring(0, dotIndex);
  }
  return text;
}
