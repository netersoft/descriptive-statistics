import 'dart:collection';
import 'dart:math' as math;

import 'rounding.dart';
import 'stats_exceptions.dart';

/// Descriptive statistics for a discrete variable (distinct values [xi] each
/// with an effectif/frequency [ni]).
class DiscreteStatsResult {
  final List<double> xi;
  final List<double> ni;
  final List<double> xini;
  final List<double> xi2ni;

  /// Ascending cumulative effectif ("N+" in the legacy app) per row.
  final List<double> cumulativeAscending;

  /// Descending cumulative effectif ("N-" in the legacy app) per row.
  final List<double> cumulativeDescending;

  final double weightedMean;

  /// `ΣNi / n` -- despite the name, this is the mean of the *effectifs*, not
  /// of the xi values. Preserved as-is from the legacy app's "moyenne simple".
  final double simpleMean;

  final double mode;

  /// Every Xi tied for the highest effectif, ascending. Length 1 unless the
  /// distribution has no unique mode (bimodal/multimodal); [mode] is always
  /// [modes].first.
  final List<double> modes;

  bool get isModeUnique => modes.length == 1;

  final double median;
  final double firstQuartile;
  final double thirdQuartile;
  final double interquartileRange;
  final double firstDecile;
  final double ninthDecile;

  /// Set only when the ascending cumulative effectif lands *exactly* on the
  /// threshold (e.g. N+ = ΣNi/2 for the median). This app follows the
  /// course's "cumulative effectif directly above" rule, which then picks
  /// the next value; another common convention takes the midpoint between
  /// the two values instead. These hold that midpoint, so the explanation
  /// can show it and a user taught the other convention isn't lost.
  final double? medianMidpoint;
  final double? firstQuartileMidpoint;
  final double? thirdQuartileMidpoint;
  final double? firstDecileMidpoint;
  final double? ninthDecileMidpoint;

  final double variance;

  /// Covariance between the xi values and their own effectifs, exactly as
  /// the legacy app computes it (not a covariance between two independent
  /// variables).
  final double covariance;
  final double correlation;
  final double standardDeviation;
  final double standardError;
  final double coefficientOfVariation;
  final double range;

  /// False when all Ni are identical, making the standard deviation of Ni
  /// zero and the correlation formula's denominator zero (0/0 -> NaN).
  bool get isCorrelationDefined => !correlation.isNaN;

  /// False when the weighted mean is zero, making the coefficient of
  /// variation's denominator zero (a finite or zero numerator over zero ->
  /// Infinity or NaN).
  bool get isCoefficientOfVariationDefined => coefficientOfVariation.isFinite;

  bool get isHomogeneous => coefficientOfVariation <= 33;

  const DiscreteStatsResult({
    required this.xi,
    required this.ni,
    required this.xini,
    required this.xi2ni,
    required this.cumulativeAscending,
    required this.cumulativeDescending,
    required this.weightedMean,
    required this.simpleMean,
    required this.mode,
    required this.modes,
    required this.median,
    required this.firstQuartile,
    required this.thirdQuartile,
    required this.interquartileRange,
    required this.firstDecile,
    required this.ninthDecile,
    required this.variance,
    required this.covariance,
    required this.correlation,
    required this.standardDeviation,
    required this.standardError,
    required this.coefficientOfVariation,
    required this.range,
    this.medianMidpoint,
    this.firstQuartileMidpoint,
    this.thirdQuartileMidpoint,
    this.firstDecileMidpoint,
    this.ninthDecileMidpoint,
  });
}

/// Computes descriptive statistics for a discrete variable given its values
/// [xi] and their effectifs [ni]. Rows sharing the same (rounded) Xi are
/// merged by summing their Ni, and the result is sorted ascending by Xi
/// regardless of input order. Mirrors `DiscreteVariablesFragment.parsing()`
/// from the legacy Android app.
DiscreteStatsResult computeDiscreteStats(
  List<double> xi,
  List<double> ni, {
  int precision = 3,
}) {
  if (xi.length != ni.length) {
    throw const StatsInputException(StatsErrorReason.lengthMismatch);
  }
  if (xi.length < 2) {
    throw const StatsInputException(StatsErrorReason.insufficientData);
  }

  final rawXi = List<double>.generate(xi.length, (i) => arrondi(xi[i], precision));
  final rawNi = List<double>.generate(xi.length, (i) => arrondi(ni[i], precision));
  if (rawNi.any((value) => value < 0)) {
    throw const StatsInputException(StatsErrorReason.negativeEffectif);
  }

  // Merge rows that share the same Xi (summing their Ni) and sort ascending
  // by Xi -- the cumulative-frequency logic below assumes one row per
  // distinct value, visited in ascending order, but nothing about the entry
  // form requires the user to type rows in that order.
  final aggregated = SplayTreeMap<double, double>();
  for (var i = 0; i < rawXi.length; i++) {
    aggregated[rawXi[i]] = (aggregated[rawXi[i]] ?? 0) + rawNi[i];
  }
  final xiR = aggregated.keys.toList();
  final niR = aggregated.values.toList();

  final n = xiR.length;
  if (n < 2) {
    // All rows shared the same Xi and collapsed into a single one.
    throw const StatsInputException(StatsErrorReason.insufficientData);
  }
  var niSum = 0.0;
  var xiSum = 0.0;
  var xiniSum = 0.0;
  var maxNi = 0.0;
  final modeIndices = <int>[];
  var xiMax = xiR[0];
  var xiMin = xiR[0];
  final xini = List<double>.filled(n, 0);
  final xi2ni = List<double>.filled(n, 0);

  for (var i = 0; i < n; i++) {
    niSum += niR[i];
    xiSum += xiR[i];
    xini[i] = arrondi(niR[i] * xiR[i], precision);
    xi2ni[i] = arrondi(xiR[i] * xiR[i] * niR[i], precision);
    xiniSum += xini[i];

    if (niR[i] > maxNi) {
      maxNi = niR[i];
      modeIndices
        ..clear()
        ..add(i);
    } else if (niR[i] == maxNi) {
      modeIndices.add(i);
    }
    if (xiR[i] > xiMax) xiMax = xiR[i];
    if (xiR[i] < xiMin) xiMin = xiR[i];
  }
  if (niSum == 0) {
    throw const StatsInputException(StatsErrorReason.zeroTotalEffectif);
  }

  final up = List<double>.filled(n, 0);
  final down = List<double>.filled(n, 0);
  final medianOperator = List<double>.filled(n, 0);
  final firstQuartOperator = List<double>.filled(n, 0);
  final thirdQuartOperator = List<double>.filled(n, 0);
  final firstDecileOperator = List<double>.filled(n, 0);
  final ninthDecileOperator = List<double>.filled(n, 0);

  var covarianceSum = 0.0;
  var xSquaresSum = 0.0;
  var ySquaresSum = 0.0;
  final xMean = xiSum / n;
  final yMean = niSum / n;

  for (var i = 0; i < n; i++) {
    up[i] = i == 0 ? arrondi(niR[i], precision) : arrondi(up[i - 1] + niR[i], precision);
    down[i] = i == 0 ? arrondi(niSum, precision) : arrondi(down[i - 1] - niR[i - 1], precision);

    final v1 = niR[i] - yMean;
    final v2 = xiR[i] - xMean;

    medianOperator[i] = up[i] - niSum / 2;
    firstQuartOperator[i] = up[i] - niSum / 4;
    thirdQuartOperator[i] = up[i] - (niSum * 3) / 4;
    firstDecileOperator[i] = up[i] - niSum / 10;
    ninthDecileOperator[i] = up[i] - (niSum * 9) / 10;

    covarianceSum += v2 * v1;
    xSquaresSum += v2 * v2;
    ySquaresSum += v1 * v1;
  }

  final medianIndex = _firstIndexPastThreshold(medianOperator);
  final firstQuartIndex = _firstIndexPastThreshold(firstQuartOperator);
  final thirdQuartIndex = _firstIndexPastThreshold(thirdQuartOperator);
  final firstDecileIndex = _firstIndexPastThreshold(firstDecileOperator);
  final ninthDecileIndex = _firstIndexPastThreshold(ninthDecileOperator);

  final weightedMean = arrondi(xiniSum / niSum, precision);
  final simpleMean = arrondi(niSum / n, precision);
  final modes = [for (final i in modeIndices) arrondi(xiR[i], precision)];
  final mode = modes.first;
  final median = arrondi(xiR[medianIndex], precision);
  final firstQuartile = arrondi(xiR[firstQuartIndex], precision);
  final thirdQuartile = arrondi(xiR[thirdQuartIndex], precision);
  final firstDecile = arrondi(xiR[firstDecileIndex], precision);
  final ninthDecile = arrondi(xiR[ninthDecileIndex], precision);
  final interquartileRange = arrondi(thirdQuartile - firstQuartile, precision);
  // Computed as Σni(xi − x̄)²/Σni from the unrounded mean rather than the
  // equivalent Σxi²ni/Σni − x̄² shown in the explanation: with large Xi,
  // subtracting two huge, nearly equal terms (one built from the already
  // rounded mean) wipes out the result -- it could even come out negative,
  // turning the standard deviation and CV into NaN.
  final exactMean = xiniSum / niSum;
  var squaredDeviationsSum = 0.0;
  for (var i = 0; i < n; i++) {
    squaredDeviationsSum += niR[i] * (xiR[i] - exactMean) * (xiR[i] - exactMean);
  }
  final variance = arrondi(squaredDeviationsSum / niSum, precision);
  final covariance = arrondi(covarianceSum / (n - 1), precision);
  final xDeviation = math.sqrt(xSquaresSum / (n - 1));
  final yDeviation = math.sqrt(ySquaresSum / (n - 1));
  final correlation = arrondi(covariance / (xDeviation * yDeviation), precision);
  final standardDeviation = arrondi(math.sqrt(variance), precision);
  final standardError = arrondi(standardDeviation / math.sqrt(n), precision);
  final coefficientOfVariation = arrondi((standardDeviation / weightedMean) * 100, precision);
  // Rounded to the configured precision like every other stat here --
  // deliberately not left as a raw double the way the legacy app displays
  // it, which can otherwise show a distracting long float tail.
  final range = arrondi(xiMax - xiMin, precision);

  return DiscreteStatsResult(
    xi: xiR,
    ni: niR,
    xini: xini,
    xi2ni: xi2ni,
    cumulativeAscending: up,
    cumulativeDescending: down,
    weightedMean: weightedMean,
    simpleMean: simpleMean,
    mode: mode,
    modes: modes,
    median: median,
    firstQuartile: firstQuartile,
    thirdQuartile: thirdQuartile,
    interquartileRange: interquartileRange,
    firstDecile: firstDecile,
    ninthDecile: ninthDecile,
    variance: variance,
    covariance: covariance,
    correlation: correlation,
    standardDeviation: standardDeviation,
    standardError: standardError,
    coefficientOfVariation: coefficientOfVariation,
    range: range,
    medianMidpoint: _midpointOnExactTie(medianOperator, medianIndex, xiR, precision),
    firstQuartileMidpoint: _midpointOnExactTie(firstQuartOperator, firstQuartIndex, xiR, precision),
    thirdQuartileMidpoint: _midpointOnExactTie(thirdQuartOperator, thirdQuartIndex, xiR, precision),
    firstDecileMidpoint: _midpointOnExactTie(firstDecileOperator, firstDecileIndex, xiR, precision),
    ninthDecileMidpoint: _midpointOnExactTie(ninthDecileOperator, ninthDecileIndex, xiR, precision),
  );
}

/// Index of the class whose ascending-cumulative-effectif just crosses a
/// given threshold (half/quarter/tenth of the total effectif for the
/// median/quartiles/deciles). Since the cumulative effectif is
/// non-decreasing, `operatorValues` (cumulative minus threshold) is also
/// non-decreasing, so its first positive entry is also its smallest one --
/// this is equivalent to (but simpler than) the legacy app's "track the
/// smallest positive value seen" scan. Defaults to 0 if the data never
/// crosses the threshold, matching the legacy app's default index.
int _firstIndexPastThreshold(List<double> operatorValues) {
  for (var i = 0; i < operatorValues.length; i++) {
    if (operatorValues[i] > 0) return i;
  }
  return 0;
}

/// When some row's cumulative effectif lands exactly on the threshold
/// (`operatorValues[i] == 0`), the "directly above" rule skips to
/// [chosenIndex], the next row past it. Returns the midpoint between that
/// row's Xi and the chosen one -- what the "average the two central values"
/// convention would give -- or null when no row lands exactly on it.
double? _midpointOnExactTie(List<double> operatorValues, int chosenIndex, List<double> xi, int precision) {
  for (var i = 0; i < chosenIndex; i++) {
    if (operatorValues[i].abs() < 1e-9) {
      return arrondi((xi[i] + xi[chosenIndex]) / 2, precision);
    }
  }
  return null;
}
