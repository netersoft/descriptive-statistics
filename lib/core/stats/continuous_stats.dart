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

  /// Index of the modal class (highest effectif).
  final int modalClassIndex;

  /// Index of the median class (where the cumulative effectif crosses half
  /// the total).
  final int medianClassIndex;

  final double weightedMean;

  /// `ΣNi / n` -- despite the name, this is the mean of the *effectifs*, not
  /// of the class midpoints. Preserved as-is from the legacy app's
  /// "moyenne simple".
  final double simpleMean;

  final double mode;
  final double median;
  final double firstQuartile;
  final double thirdQuartile;
  final double interquartileRange;

  /// Looked up at the class midpoint rather than interpolated within the
  /// class -- preserved as-is from the legacy app, which (inconsistently
  /// with how it computes the median/quartiles) does the same.
  final double firstDecile;
  final double ninthDecile;

  final double variance;

  /// Covariance between the class midpoints and their own effectifs, exactly
  /// as the legacy app computes it (not a covariance between two
  /// independent variables).
  final double covariance;
  final double correlation;
  final double standardDeviation;
  final double standardError;
  final double coefficientOfVariation;
  final double range;

  bool get isHomogeneous => coefficientOfVariation <= 33;

  const ContinuousStatsResult({
    required this.xi,
    required this.ni,
    required this.xini,
    required this.xi2ni,
    required this.cumulativeAscending,
    required this.cumulativeDescending,
    required this.modalClassIndex,
    required this.medianClassIndex,
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

  final niR = List<double>.generate(n, (i) => arrondi(cni[i], precision));
  if (niR.any((value) => value < 0)) {
    throw const StatsInputException(StatsErrorReason.negativeEffectif);
  }
  final xiR = List<double>.generate(n, (i) => arrondi((cl1[i] + cl2[i]) / 2, precision));

  var niSum = 0.0;
  var xiSum = 0.0;
  var xiniSum = 0.0;
  var xi2niSum = 0.0;
  var maxNiIndex = 0;
  var maxNi = 0.0;
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
    xi2niSum += xi2ni[i];

    if (niR[i] > maxNi) {
      maxNi = niR[i];
      maxNiIndex = i;
    }
    if (cl2[i] > xiMax) xiMax = cl2[i];
    if (cl1[i] < xiMin) xiMin = cl1[i];
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

  double niAt(int index) => index >= 0 && index < n ? niR[index] : 0;
  double upBefore(int index) => index > 0 ? up[index - 1] : 0;

  final weightedMean = arrondi(xiniSum / niSum, precision);
  final simpleMean = arrondi(niSum / n, precision);

  final modeGapBefore = niR[maxNiIndex] - niAt(maxNiIndex - 1);
  final modeGapAfter = niR[maxNiIndex] - niAt(maxNiIndex + 1);
  final mode = arrondi(
    cl1[maxNiIndex] + k[maxNiIndex] * (modeGapBefore / (modeGapBefore + modeGapAfter)),
    precision,
  );

  final median = arrondi(
    cl1[medianIndex] + k[medianIndex] * ((niSum / 2 - upBefore(medianIndex)) / niR[medianIndex]),
    precision,
  );
  final firstQuartile = arrondi(
    cl1[firstQuartIndex] + k[firstQuartIndex] * ((niSum / 4 - upBefore(firstQuartIndex)) / niR[firstQuartIndex]),
    precision,
  );
  final thirdQuartile = arrondi(
    cl1[thirdQuartIndex] + k[thirdQuartIndex] * ((niSum * 3 / 4 - upBefore(thirdQuartIndex)) / niR[thirdQuartIndex]),
    precision,
  );
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
  final range = arrondi(xiMax - xiMin, precision);

  return ContinuousStatsResult(
    xi: xiR,
    ni: niR,
    xini: xini,
    xi2ni: xi2ni,
    cumulativeAscending: up,
    cumulativeDescending: down,
    modalClassIndex: maxNiIndex,
    medianClassIndex: medianIndex,
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

/// See the equivalent helper in `discrete_stats.dart` for why this is
/// equivalent to the legacy app's "track the smallest positive value seen"
/// scan.
int _firstIndexPastThreshold(List<double> operatorValues) {
  for (var i = 0; i < operatorValues.length; i++) {
    if (operatorValues[i] > 0) return i;
  }
  return 0;
}
