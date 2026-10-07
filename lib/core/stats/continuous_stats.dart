import 'dart:math' as math;

import 'rounding.dart';
import 'stats_exceptions.dart';

/// Descriptive statistics for a continuous (grouped/class-interval) variable
/// given class lower bounds, upper bounds, and effectifs.
class ContinuousStatsResult {
  /// Class midpoints.
  final List<double> xi;
  final List<double> ni;
  final List<double> xini;
  final List<double> xi2ni;

  /// Ascending cumulative effectif ("N+" in the legacy app) per class.
  final List<double> cumulativeAscending;

  /// Descending cumulative effectif ("N-" in the legacy app) per class.
  final List<double> cumulativeDescending;

  /// Index of the modal class (highest effectif, or highest density when
  /// [usesDensities]).
  final int modalClassIndex;

  /// Every class index tied for the highest effectif (or density), ascending. Length 1
  /// unless the distribution has no unique modal class (bimodal/
  /// multimodal); [modalClassIndex] is always [modalClassIndices].first.
  final List<int> modalClassIndices;

  bool get isModeUnique => modalClassIndices.length == 1;

  /// True when the classes don't all share the same width. The mode formula
  /// `Mo = L1 + k((N0 - N1) / ((N0 - N1) + (N0 - N2)))` compares
  /// effectifs, which is only meaningful when every class is equally wide;
  /// with unequal widths, the modal class and N0/N1/N2 are taken from the
  /// densities `Ni / k` (effectifs corrigés) instead.
  final bool usesDensities;

  /// The per-class values the mode was computed from: [ni] when classes
  /// share the same width, `Ni / k` densities otherwise (see
  /// [usesDensities]).
  final List<double> modeWeights;

  /// Class index each quantile was interpolated in (where the ascending
  /// cumulative effectif crosses 1/4, 3/4, 1/10 and 9/10 of the total).
  final int firstQuartileClassIndex;
  final int thirdQuartileClassIndex;
  final int firstDecileClassIndex;
  final int ninthDecileClassIndex;

  /// Index of the median class (where the cumulative effectif crosses half
  /// the total).
  final int medianClassIndex;

  final double weightedMean;

  /// `ΣNi / n` -- despite the name, this is the mean of the *effectifs*, not
  /// of the class midpoints. Preserved as-is from the legacy app's
  /// "moyenne simple".
  /// Mean effectif per row, ΣNi / n. The legacy app labelled it "simple
  /// arithmetic mean" with the mean's symbol X, but it is the mean of the
  /// effectifs, not of the variable (that one is [weightedMean]).
  final double meanEffectif;

  final double mode;
  final double median;
  final double firstQuartile;
  final double thirdQuartile;
  final double interquartileRange;

  /// Interpolated within their class, like the median and quartiles.
  final double firstDecile;
  final double ninthDecile;

  final double variance;

  /// Covariance between the class midpoints and their own effectifs, exactly
  /// as the legacy app computes it (not a covariance between two
  /// independent variables).
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

  /// Smallest and largest value of the series (the lowest class lower
  /// bound and highest upper bound), the ends of the box plot's whiskers.
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

  const ContinuousStatsResult({
    required this.xi,
    required this.ni,
    required this.xini,
    required this.xi2ni,
    required this.cumulativeAscending,
    required this.cumulativeDescending,
    required this.modalClassIndex,
    required this.modalClassIndices,
    required this.medianClassIndex,
    required this.usesDensities,
    required this.modeWeights,
    required this.firstQuartileClassIndex,
    required this.thirdQuartileClassIndex,
    required this.firstDecileClassIndex,
    required this.ninthDecileClassIndex,
    required this.weightedMean,
    required this.meanEffectif,
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
    required this.sampleStandardDeviation,
    required this.standardError,
    required this.coefficientOfVariation,
    required this.range,
    required this.minimum,
    required this.maximum,
    required this.precision,
  });
}

/// Computes descriptive statistics for a continuous (grouped/class-interval)
/// variable given class lower bounds [l1], upper bounds [l2], and effectifs
/// [ni]. Classes are sorted ascending by [l1] regardless of input order.
/// Mirrors `ContinuousVariablesFragment.parsing()` from the legacy app.
///
/// Unlike the legacy Java, the modal-class and median-class neighbour
/// lookups are clamped to 0 at the data's edges instead of crashing when the
/// modal or median class is the first or last one -- a latent
/// out-of-bounds bug in the original that this deliberately fixes.
ContinuousStatsResult computeContinuousStats(
  List<double> l1,
  List<double> l2,
  List<double> ni, {
  int precision = 3,
}) {
  if (l1.length != l2.length || l1.length != ni.length) {
    throw const StatsInputException(StatsErrorReason.lengthMismatch);
  }
  if (l1.length < 2) {
    throw const StatsInputException(StatsErrorReason.insufficientData);
  }

  final n = l1.length;

  // Sort classes ascending by L1 -- the cumulative-frequency logic below
  // assumes classes are visited in ascending order, but nothing about the
  // entry form requires the user to type rows in that order.
  final order = List<int>.generate(n, (i) => i)..sort((a, b) => l1[a].compareTo(l1[b]));
  final cl1 = [for (final i in order) l1[i]];
  final cl2 = [for (final i in order) l2[i]];
  final cni = [for (final i in order) ni[i]];

  final k = List<double>.generate(n, (i) => cl2[i] - cl1[i]);
  if (k.any((width) => width <= 0)) {
    throw const StatsInputException(StatsErrorReason.invalidClassWidth);
  }
  // Touching bounds ([0, 10[ then [10, 20[) and gaps (10-19 then 20-29, a
  // common way to write integer classes) are both fine; a class starting
  // before the previous one ends would count some values twice.
  for (var i = 1; i < n; i++) {
    if (cl1[i] < cl2[i - 1]) {
      throw const StatsInputException(StatsErrorReason.overlappingClasses);
    }
  }
  final usesDensities = k.any((width) => (width - k[0]).abs() > 1e-9 * k[0].abs().clamp(1, double.infinity));

  final niR = List<double>.generate(n, (i) => arrondi(cni[i], precision));
  if (niR.any((value) => value < 0)) {
    throw const StatsInputException(StatsErrorReason.negativeEffectif);
  }
  final xiR = List<double>.generate(n, (i) => arrondi((cl1[i] + cl2[i]) / 2, precision));

  var niSum = 0.0;
  var xiSum = 0.0;
  var xiniSum = 0.0;
  var xiMax = cl2[0];
  var xiMin = cl1[0];
  final xini = List<double>.filled(n, 0);
  final xi2ni = List<double>.filled(n, 0);

  for (var i = 0; i < n; i++) {
    niSum += niR[i];
    xiSum += xiR[i];
    xini[i] = arrondi(niR[i] * xiR[i], precision);
    xi2ni[i] = arrondi(xiR[i] * xiR[i] * niR[i], precision);
    xiniSum += xini[i];

    if (cl2[i] > xiMax) xiMax = cl2[i];
    if (cl1[i] < xiMin) xiMin = cl1[i];
  }
  if (niSum == 0) {
    throw const StatsInputException(StatsErrorReason.zeroTotalEffectif);
  }

  final modeWeights = usesDensities ? List<double>.generate(n, (i) => niR[i] / k[i]) : niR;
  var maxWeight = 0.0;
  final modeIndices = <int>[];
  for (var i = 0; i < n; i++) {
    if (modeWeights[i] > maxWeight) {
      maxWeight = modeWeights[i];
      modeIndices
        ..clear()
        ..add(i);
    } else if (modeWeights[i] == maxWeight) {
      modeIndices.add(i);
    }
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

  double weightAt(int index) => index >= 0 && index < n ? modeWeights[index] : 0;
  double upBefore(int index) => index > 0 ? up[index - 1] : 0;

  final weightedMean = arrondi(xiniSum / niSum, precision);
  final meanEffectif = arrondi(niSum / n, precision);

  final maxNiIndex = modeIndices.first;
  final modeGapBefore = modeWeights[maxNiIndex] - weightAt(maxNiIndex - 1);
  final modeGapAfter = modeWeights[maxNiIndex] - weightAt(maxNiIndex + 1);
  final mode = arrondi(
    cl1[maxNiIndex] + k[maxNiIndex] * (modeGapBefore / (modeGapBefore + modeGapAfter)),
    precision,
  );

  // Linear interpolation within the class where the cumulative effectif
  // crosses [fraction] of the total: L1 + k((fraction·ΣNi - N+prev) / Ni).
  double interpolate(int index, double fraction) => arrondi(cl1[index] + k[index] * ((niSum * fraction - upBefore(index)) / niR[index]), precision);

  final median = interpolate(medianIndex, 1 / 2);
  final firstQuartile = interpolate(firstQuartIndex, 1 / 4);
  final thirdQuartile = interpolate(thirdQuartIndex, 3 / 4);
  final firstDecile = interpolate(firstDecileIndex, 1 / 10);
  final ninthDecile = interpolate(ninthDecileIndex, 9 / 10);

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

  return ContinuousStatsResult(
    xi: xiR,
    ni: niR,
    xini: xini,
    xi2ni: xi2ni,
    cumulativeAscending: up,
    cumulativeDescending: down,
    modalClassIndex: maxNiIndex,
    modalClassIndices: modeIndices,
    medianClassIndex: medianIndex,
    usesDensities: usesDensities,
    modeWeights: modeWeights,
    firstQuartileClassIndex: firstQuartIndex,
    thirdQuartileClassIndex: thirdQuartIndex,
    firstDecileClassIndex: firstDecileIndex,
    ninthDecileClassIndex: ninthDecileIndex,
    weightedMean: weightedMean,
    meanEffectif: meanEffectif,
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
    sampleStandardDeviation: sampleStandardDeviation,
    standardError: standardError,
    coefficientOfVariation: coefficientOfVariation,
    range: range,
    minimum: arrondi(xiMin, precision),
    maximum: arrondi(xiMax, precision),
    precision: precision,
  );
}

/// See the equivalent helper in `discrete_stats.dart` for why this is
/// equivalent to the legacy app's "track the smallest positive value seen"
/// scan.
int _firstIndexPastThreshold(List<double> operatorValues) {
  for (var i = 0; i < operatorValues.length; i++) {
    if (operatorValues[i] > 0) return i;
  }
  return 0;
}
