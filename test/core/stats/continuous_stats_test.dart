import 'package:descriptive_statistics/core/stats/continuous_stats.dart';
import 'package:descriptive_statistics/core/stats/stats_exceptions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeContinuousStats', () {
    // Classes [0,10), [10,20), [20,30), [30,40) with ni = 5, 8, 4, 3
    // (total effectif 20). Hand-computed expectations below.
    final result = computeContinuousStats(
      [0, 10, 20, 30],
      [10, 20, 30, 40],
      [5, 8, 4, 3],
      precision: 4,
    );

    test('computes class midpoints and the intermediate table columns', () {
      expect(result.xi, [5, 15, 25, 35]);
      expect(result.ni, [5, 8, 4, 3]);
      expect(result.cumulativeAscending, [5, 13, 17, 20]);
      expect(result.cumulativeDescending, [20, 15, 7, 3]);
    });

    test('computes the weighted mean and the mean effectif', () {
      expect(result.weightedMean, closeTo(17.5, 1e-9));
      expect(result.meanEffectif, closeTo(5.0, 1e-9));
    });

    test('finds the modal and median classes and interpolates within them', () {
      expect(result.modalClassIndex, 1);
      expect(result.medianClassIndex, 1);
      expect(result.mode, closeTo(14.2857, 1e-3));
      expect(result.median, closeTo(16.25, 1e-9));
      expect(result.firstQuartile, closeTo(10.0, 1e-9));
      expect(result.thirdQuartile, closeTo(25.0, 1e-9));
      expect(result.interquartileRange, closeTo(15.0, 1e-9));
    });

    test('interpolates deciles within their class, like the median and quartiles', () {
      // D1: ΣNi/10 = 2 falls in [0,10) -> 0 + 10 * ((2 - 0) / 5) = 4.
      // D9: 9ΣNi/10 = 18 falls in [30,40) -> 30 + 10 * ((18 - 17) / 3).
      expect(result.firstDecileClassIndex, 0);
      expect(result.ninthDecileClassIndex, 3);
      expect(result.firstDecile, 4);
      expect(result.ninthDecile, closeTo(33.3333, 1e-3));
    });

    test('keeps using effectifs for the mode when every class has the same width', () {
      expect(result.usesDensities, isFalse);
      expect(result.modeWeights, result.ni);
    });

    test('computes variance, standard deviation, and standard error', () {
      expect(result.variance, closeTo(98.75, 1e-3));
      expect(result.standardDeviation, closeTo(9.9373, 1e-3));
      // s = σ·√(20/19) = 10.1955, SE = s / √20.
      expect(result.sampleStandardDeviation, closeTo(10.1955, 1e-3));
      expect(result.standardError, closeTo(2.2798, 1e-3));
    });

    test('computes covariance and correlation', () {
      expect(result.covariance, closeTo(-16.6667, 1e-3));
      expect(result.correlation, closeTo(-0.5977, 1e-3));
    });

    test('computes the range and flags heterogeneity', () {
      expect(result.range, 40);
      expect(result.isHomogeneous, false);
    });

    test('gives the lowest and highest class bounds for the box plot whiskers', () {
      expect(result.minimum, 0);
      expect(result.maximum, 40);
    });

    test('handles a modal class at the first index without crashing', () {
      final edgeResult = computeContinuousStats(
        [0, 10, 20],
        [10, 20, 30],
        [10, 4, 2],
      );

      expect(edgeResult.modalClassIndex, 0);
      expect(edgeResult.mode.isFinite, true);
    });

    test('handles a modal class at the last index without crashing', () {
      final edgeResult = computeContinuousStats(
        [0, 10, 20],
        [10, 20, 30],
        [2, 4, 10],
      );

      expect(edgeResult.modalClassIndex, 2);
      expect(edgeResult.mode.isFinite, true);
    });

    test('flags a unique modal class', () {
      expect(result.isModeUnique, true);
      expect(result.modalClassIndices, [1]);
    });

    test('reports every class index tied for the highest effectif when the mode is not unique', () {
      final bimodal = computeContinuousStats(
        [0, 10, 20, 30],
        [10, 20, 30, 40],
        [5, 8, 8, 3],
      );

      expect(bimodal.isModeUnique, false);
      expect(bimodal.modalClassIndices, [1, 2]);
      expect(bimodal.modalClassIndex, 1);
    });

    test('sorts classes by L1 regardless of input order', () {
      // Same classes/effectifs as the main fixture above, entered out of
      // order -- the cumulative-frequency logic requires ascending L1.
      final outOfOrder = computeContinuousStats(
        [20, 0, 30, 10],
        [30, 10, 40, 20],
        [4, 5, 3, 8],
        precision: 4,
      );

      expect(outOfOrder.xi, [5, 15, 25, 35]);
      expect(outOfOrder.ni, [5, 8, 4, 3]);
      expect(outOfOrder.median, closeTo(16.25, 1e-9));
    });

    test('throws on a negative class width', () {
      expect(
        () => computeContinuousStats([0, 20], [10, 15], [5, 5]),
        throwsA(
          isA<StatsInputException>().having((e) => e.reason, 'reason', StatsErrorReason.invalidClassWidth),
        ),
      );
    });

    test('throws on a zero-width class', () {
      expect(
        () => computeContinuousStats([0, 10], [10, 10], [5, 5]),
        throwsA(
          isA<StatsInputException>().having((e) => e.reason, 'reason', StatsErrorReason.invalidClassWidth),
        ),
      );
    });

    test('throws on a negative effectif', () {
      expect(
        () => computeContinuousStats([0, 10], [10, 20], [5, -1]),
        throwsA(
          isA<StatsInputException>().having((e) => e.reason, 'reason', StatsErrorReason.negativeEffectif),
        ),
      );
    });

    test('throws when every effectif is zero', () {
      expect(
        () => computeContinuousStats([0, 10], [10, 20], [0, 0]),
        throwsA(
          isA<StatsInputException>().having((e) => e.reason, 'reason', StatsErrorReason.zeroTotalEffectif),
        ),
      );
    });

    test('flags correlation as undefined when every class has the same Ni', () {
      // All Ni equal -> zero variance for Ni -> the correlation formula's
      // denominator is 0, so covariance/(0*x) is 0/0 (NaN), not an exception.
      final flatNi = computeContinuousStats(
        [0, 10, 20, 30],
        [10, 20, 30, 40],
        [5, 5, 5, 5],
      );

      expect(flatNi.correlation.isNaN, true);
      expect(flatNi.isCorrelationDefined, false);
    });

    test('flags coefficient of variation as undefined when the weighted mean is zero', () {
      // Midpoints -5 and 5 with equal Ni -> weighted mean is 0, so
      // (stdDev / 0) * 100 is Infinity, not an exception.
      final zeroMean = computeContinuousStats([-10, 0], [0, 10], [1, 1]);

      expect(zeroMean.weightedMean, 0);
      expect(zeroMean.coefficientOfVariation.isFinite, false);
      expect(zeroMean.isCoefficientOfVariationDefined, false);
    });

    test('throws on mismatched lengths', () {
      expect(
        () => computeContinuousStats([0, 10], [10, 20], [5]),
        throwsA(
          isA<StatsInputException>().having((e) => e.reason, 'reason', StatsErrorReason.lengthMismatch),
        ),
      );
    });

    test('throws on insufficient data', () {
      expect(
        () => computeContinuousStats([0], [10], [5]),
        throwsA(
          isA<StatsInputException>().having((e) => e.reason, 'reason', StatsErrorReason.insufficientData),
        ),
      );
    });
  });

  group('computeContinuousStats variance precision', () {
    test('stays exact for large, narrow classes', () {
      // Midpoints 1000.5 and 1001.5 with ni 1 and 2: mean 1001.1667,
      // variance = (1·0.6667² + 2·0.3333²)/3 = 0.2222. The old
      // Σxi²ni/Σni − x̄² form (with x̄ rounded) returned a negative value.
      final result = computeContinuousStats([1000, 1001], [1001, 1002], [1, 2]);

      expect(result.variance, closeTo(2 / 9, 1e-3));
      expect(result.standardDeviation.isNaN, isFalse);
    });
  });

  group('computeContinuousStats class validation', () {
    test('rejects overlapping classes', () {
      expect(
        () => computeContinuousStats([0, 5], [10, 15], [1, 1]),
        throwsA(isA<StatsInputException>().having((e) => e.reason, 'reason', StatsErrorReason.overlappingClasses)),
      );
    });

    test('detects the overlap regardless of input order', () {
      expect(
        () => computeContinuousStats([5, 0], [15, 10], [1, 1]),
        throwsA(isA<StatsInputException>().having((e) => e.reason, 'reason', StatsErrorReason.overlappingClasses)),
      );
    });

    test('accepts touching bounds and gaps between classes', () {
      expect(() => computeContinuousStats([0, 10], [10, 20], [1, 1]), returnsNormally);
      // Integer-style classes: 10-19 then 20-29.
      expect(() => computeContinuousStats([10, 20], [19, 29], [1, 1]), returnsNormally);
    });
  });

  group('computeContinuousStats mode with unequal class widths', () {
    // Effectifs alone would pick [10,30) (16 > 10), but it's twice as wide:
    // densities are 10/10 = 1, 16/20 = 0.8 and 6/10 = 0.6, so the modal
    // class is [0,10): Mo = 0 + 10 * ((1 - 0) / ((1 - 0) + (1 - 0.8))).
    final result = computeContinuousStats([0, 10, 30], [10, 30, 40], [10, 16, 6]);

    test('picks the modal class and interpolates from densities', () {
      expect(result.usesDensities, isTrue);
      expect(result.modeWeights, [1, 0.8, 0.6]);
      expect(result.modalClassIndex, 0);
      expect(result.mode, closeTo(8.333, 1e-3));
    });
  });

  group('closeClassGaps', () {
    test('reads integer classes written with a gap as touching classes', () {
      expect(closeClassGaps([10, 20, 30], [19, 29, 39]), [20, 30, 40]);
      expect(closeClassGaps([30, 10, 20], [39, 19, 29]), [40, 20, 30]);
      expect(closeClassGaps([1.5, 2.5], [2.4, 3.4]), [2.5, 3.5]);
    });

    test('leaves touching, irregular or wide gaps alone', () {
      expect(closeClassGaps([10, 20, 30], [20, 30, 40]), [20, 30, 40]);
      expect(closeClassGaps([10, 20, 32], [19, 29, 39]), [19, 29, 39]);
      // A gap as wide as a class is more likely a missing class.
      expect(closeClassGaps([0, 20], [10, 30]), [10, 30]);
    });

    test('gives the same results as the classes written [10 ; 20[', () {
      final gaps = computeContinuousStats([10, 20, 30], [19, 29, 39], [5, 8, 7]);
      final touching = computeContinuousStats([10, 20, 30], [20, 30, 40], [5, 8, 7]);
      expect(gaps.classGapsClosed, isTrue);
      expect(touching.classGapsClosed, isFalse);
      expect(gaps.median, touching.median);
      expect(gaps.mode, touching.mode);
      expect(gaps.weightedMean, touching.weightedMean);
      expect(gaps.range, 30);
    });
  });
}
