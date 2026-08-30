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
  final double median;
  final double firstQuartile;
  final double thirdQuartile;
  final double interquartileRange;
  final double firstDecile;
  final double ninthDecile;
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
  });
}

/// Computes descriptive statistics for a discrete variable given its values
/// [xi] and their effectifs [ni]. Mirrors
/// `DiscreteVariablesFragment.parsing()` from the legacy Android app.
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

  final n = xi.length;
  final xiR = List<double>.generate(n, (i) => arrondi(xi[i], precision));
  final niR = List<double>.generate(n, (i) => arrondi(ni[i], precision));

  var niSum = 0.0;
  var xiSum = 0.0;
  var xiniSum = 0.0;
  var xi2niSum = 0.0;
  var maxNiIndex = 0;
  var maxNi = 0.0;
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
    xi2niSum += xi2ni[i];

    if (niR[i] > maxNi) {
      maxNi = niR[i];
      maxNiIndex = i;
    }
    if (xiR[i] > xiMax) xiMax = xiR[i];
    if (xiR[i] < xiMin) xiMin = xiR[i];
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
  final mode = arrondi(xiR[maxNiIndex], precision);
  final median = arrondi(xiR[medianIndex], precision);
  final firstQuartile = arrondi(xiR[firstQuartIndex], precision);
  final thirdQuartile = arrondi(xiR[thirdQuartIndex], precision);
  final firstDecile = arrondi(xiR[firstDecileIndex], precision);
  final ninthDecile = arrondi(xiR[ninthDecileIndex], precision);
  final interquartileRange = arrondi(thirdQuartile - firstQuartile, precision);
  final variance = arrondi((xi2niSum / niSum) - weightedMean * weightedMean, precision);
  final covariance = arrondi(covarianceSum / (n - 1), precision);
  final xDeviation = math.sqrt(xSquaresSum / (n - 1));
  final yDeviation = math.sqrt(ySquaresSum / (n - 1));
  final correlation = arrondi(covariance / (xDeviation * yDeviation), precision);
  final standardDeviation = arrondi(math.sqrt(variance), precision);
  final standardError = arrondi(standardDeviation / math.sqrt(n), precision);
  final coefficientOfVariation = arrondi((standardDeviation / weightedMean) * 100, precision);
  final range = xiMax - xiMin;

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
