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
  /// Mean effectif per row, ΣNi / n. The legacy app labelled it "simple
  /// arithmetic mean" with the mean's symbol X, but it is the mean of the
  /// effectifs, not of the variable (that one is [weightedMean]).
  final double meanEffectif;

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

  /// The two central values the median is the mean of, when the ascending
  /// cumulative effectif lands exactly on ΣNi/2 (an even total effectif
  /// split between two values); null otherwise.
  final (double, double)? medianTieValues;

  final double variance;

  /// Covariance between the xi values and their own effectifs, exactly as
  /// the legacy app computes it (not a covariance between two independent
  /// variables).
  final double covariance;
  final double correlation;
  final double standardDeviation;

  /// Sample standard deviation s = √(Σni(xi − x̄)² / (ΣNi − 1)), the estimate
  /// the standard error is built on (NaN when ΣNi ≤ 1).
  final double sampleStandardDeviation;

  /// Standard error of the mean, s / √ΣNi (NaN when ΣNi ≤ 1).
  final double standardError;
  final double coefficientOfVariation;
  final double range;

  /// Smallest and largest Xi, the ends of the box plot's whiskers.
  final double minimum;
  final double maximum;

  /// Decimal places every value above was rounded to. Carried with the
  /// result so anything rendering it later (explanation, saved backup)
  /// rounds its intermediate values the same way, even if the setting has
  /// changed since.
  final int precision;

  /// False when all Ni are identical, making the standard deviation of Ni
  /// zero and the correlation formula's denominator zero (0/0 -> NaN).
  bool get isCorrelationDefined => !correlation.isNaN;

  /// False when the weighted mean is zero, making the coefficient of
  /// variation's denominator zero (a finite or zero numerator over zero ->
  /// Infinity or NaN).
  bool get isCoefficientOfVariationDefined => coefficientOfVariation.isFinite;

  /// False when the total effectif is 1 or less: the sample standard
  /// deviation divides by ΣNi − 1.
  bool get isStandardErrorDefined => standardError.isFinite;

  bool get isHomogeneous => coefficientOfVariation <= 33;

  const DiscreteStatsResult({
    required this.xi,
    required this.ni,
    required this.xini,
    required this.xi2ni,
    required this.cumulativeAscending,
    required this.cumulativeDescending,
    required this.weightedMean,
    required this.meanEffectif,
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
    required this.sampleStandardDeviation,
    required this.standardError,
    required this.coefficientOfVariation,
    required this.range,
    required this.minimum,
    required this.maximum,
    required this.precision,
    this.medianTieValues,
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
  final meanEffectif = arrondi(niSum / n, precision);
  final modes = [for (final i in modeIndices) arrondi(xiR[i], precision)];
  final mode = modes.first;
  // French definition (collège/lycée): the median of an even total
  // effectif is the mean of the two central values, i.e. when N+ lands
  // exactly on ΣNi/2, of that value and the next one.
  // The next value of the series skips rows with a zero effectif.
  final nextIndex = medianOperator[medianIndex].abs() < _tieTolerance
      ? [
          for (var j = medianIndex + 1; j < n; j++)
            if (niR[j] > 0) j,
        ].firstOrNull
      : null;
  final medianTieValues = nextIndex == null ? null : (xiR[medianIndex], xiR[nextIndex]);
  final median = arrondi(medianTieValues == null ? xiR[medianIndex] : (medianTieValues.$1 + medianTieValues.$2) / 2, precision);
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
  // The legacy app divided σ by √(number of rows), so the standard error
  // ignored the effectifs: ten times more observations gave the same value.
  // It is the standard error of the mean, s / √N with N = ΣNi and s the
  // sample standard deviation (Bessel's N − 1), s = σ·√(N / (N − 1)).
  final sampleStandardDeviation = niSum > 1 ? arrondi(standardDeviation * math.sqrt(niSum / (niSum - 1)), precision) : double.nan;
  final standardError = niSum > 1 ? arrondi(sampleStandardDeviation / math.sqrt(niSum), precision) : double.nan;
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
    meanEffectif: meanEffectif,
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
    sampleStandardDeviation: sampleStandardDeviation,
    standardError: standardError,
    coefficientOfVariation: coefficientOfVariation,
    range: range,
    minimum: arrondi(xiMin, precision),
    maximum: arrondi(xiMax, precision),
    precision: precision,
    medianTieValues: medianTieValues,
  );
}

/// Cumulative effectifs come from sums of (possibly decimal) Ni; this keeps
/// one landing exactly on a threshold from missing it by a rounding error.
const _tieTolerance = 1e-9;

/// Index of the first value whose ascending cumulative effectif reaches the
/// threshold (half/quarter/tenth of the total effectif for the
/// median/quartiles/deciles): `operatorValues` is cumulative minus
/// threshold. This is the French definition -- Q1 is the smallest value
/// such that at least 25 % of the data are less than or equal to it. The
/// legacy app required the cumulative effectif to be strictly above the
/// threshold, which on an exact tie picked the next value (Q1 = 2 for 1, 2,
/// 3, 4 instead of 1), matching no usual definition. Defaults to 0 if the
/// data never reaches the threshold.
int _firstIndexPastThreshold(List<double> operatorValues) {
  for (var i = 0; i < operatorValues.length; i++) {
    if (operatorValues[i] > -_tieTolerance) return i;
  }
  return 0;
}
