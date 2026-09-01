import 'dart:math' as math;

/// Rounds [value] to [decimals] decimal places, half away from zero.
///
/// Mirrors the legacy Android app's `arrondi()`, which cast
/// `(int) (value * 10^decimals + 0.5)` -- that truncates toward zero, so it
/// rounds negative halves the wrong way (e.g. -2.45 would become -2.4
/// instead of -2.5). This applies the same half-up rule symmetrically for
/// negative values instead of blindly porting that bug.
///
/// The tiny epsilon nudges values whose binary floating-point representation
/// falls a hair short of the true decimal half (e.g. 1.005 is actually
/// stored as ~1.00499999999999989), which would otherwise round down --
/// without it, `arrondi(1.005, 2)` returns 1.0 instead of 1.01.
double arrondi(double value, int decimals) {
  const epsilon = 1e-9;
  final factor = math.pow(10, decimals).toDouble();
  final rounded = (value.abs() * factor + 0.5 + epsilon).truncateToDouble();
  return (value.isNegative ? -rounded : rounded) / factor;
}

/// Formats [value] without a trailing ".0" for whole numbers, matching the
/// legacy app's `noZero()`. Uses [decimalSeparator] between the whole and
/// fractional parts (default '.') -- pass ',' to match the fr/de/es/pt
/// convention `parseDecimal` already accepts on input, so results are shown
/// the same way the user typed them.
String noZero(double value, {String decimalSeparator = '.'}) {
  final text = value.toString();
  final dotIndex = text.indexOf('.');
  final whole = dotIndex == -1 ? text : text.substring(0, dotIndex);
  final fraction = dotIndex == -1 ? '' : text.substring(dotIndex + 1);
  if (fraction == '0' || fraction.isEmpty) {
    return whole;
  }
  return '$whole$decimalSeparator$fraction';
}
