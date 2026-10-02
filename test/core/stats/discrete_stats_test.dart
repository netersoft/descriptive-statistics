import 'package:descriptive_statistics/core/stats/discrete_stats.dart';
import 'package:descriptive_statistics/core/stats/stats_exceptions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeDiscreteStats', () {
    // xi: 1..5, ni: 2,4,6,4,2 (symmetric around xi=3, total effectif 18).
    // Hand-computed expectations below (see PR description / commit for the
    // full derivation).
    final result = computeDiscreteStats(
      [1, 2, 3, 4, 5],
      [2, 4, 6, 4, 2],
      precision: 4,
    );

    test('computes the intermediate table columns', () {
      expect(result.xi, [1, 2, 3, 4, 5]);
      expect(result.ni, [2, 4, 6, 4, 2]);
      expect(result.xini, [2, 8, 18, 16, 10]);
      expect(result.xi2ni, [2, 16, 54, 64, 50]);
      expect(result.cumulativeAscending, [2, 6, 12, 16, 18]);
      expect(result.cumulativeDescending, [18, 16, 12, 6, 2]);
    });

    test('computes the weighted and simple means', () {
      expect(result.weightedMean, closeTo(3.0, 1e-9));
      expect(result.simpleMean, closeTo(3.6, 1e-9));
    });

    test('computes mode, median, quartiles, and deciles', () {
      expect(result.mode, 3);
      expect(result.median, 3);
      expect(result.firstQuartile, 2);
      expect(result.thirdQuartile, 4);
      expect(result.interquartileRange, 2);
      expect(result.firstDecile, 1);
      expect(result.ninthDecile, 5);
    });

    test('computes variance, standard deviation, and standard error', () {
      expect(result.variance, closeTo(4.0 / 3.0, 1e-4));
      expect(result.standardDeviation, closeTo(1.1547, 1e-3));
      expect(result.standardError, closeTo(0.5164, 1e-3));
    });

    test('computes the coefficient of variation and flags it heterogeneous', () {
      expect(result.coefficientOfVariation, closeTo(38.49, 1e-1));
      expect(result.isHomogeneous, false);
    });

    test('computes the range', () {
      expect(result.range, 4);
    });

    test('gives the smallest and largest Xi for the box plot whiskers', () {
      final unordered = computeDiscreteStats([7, -2, 3], [1, 1, 1]);
      expect(unordered.minimum, -2);
      expect(unordered.maximum, 7);
    });

    test('covariance and correlation are 0 for this symmetric distribution', () {
      expect(result.covariance, closeTo(0.0, 1e-9));
      expect(result.correlation, closeTo(0.0, 1e-9));
    });

    test('mean lies within [xiMin, xiMax] and frequencies stay consistent', () {
      expect(result.weightedMean, greaterThanOrEqualTo(1));
      expect(result.weightedMean, lessThanOrEqualTo(5));
      expect(result.ni.reduce((a, b) => a + b), 18);
    });

    test('throws on mismatched lengths', () {
      expect(
        () => computeDiscreteStats([1, 2], [1]),
        throwsA(
          isA<StatsInputException>().having((e) => e.reason, 'reason', StatsErrorReason.lengthMismatch),
        ),
      );
    });

    test('throws on insufficient data', () {
      expect(
        () => computeDiscreteStats([1], [1]),
        throwsA(
          isA<StatsInputException>().having((e) => e.reason, 'reason', StatsErrorReason.insufficientData),
        ),
      );
    });

    test('throws on a negative effectif', () {
      expect(
        () => computeDiscreteStats([1, 2], [3, -1]),
        throwsA(
          isA<StatsInputException>().having((e) => e.reason, 'reason', StatsErrorReason.negativeEffectif),
        ),
      );
    });

    test('throws when every effectif is zero', () {
      expect(
        () => computeDiscreteStats([1, 2], [0, 0]),
        throwsA(
          isA<StatsInputException>().having((e) => e.reason, 'reason', StatsErrorReason.zeroTotalEffectif),
        ),
      );
    });

    test('sorts rows by Xi regardless of input order', () {
      // Same distribution as the symmetric fixture above (xi 1..5, ni 2,4,6,4,2)
      // but entered out of order -- the cumulative-frequency logic requires
      // ascending Xi, so results must match the sorted fixture exactly.
      final outOfOrder = computeDiscreteStats(
        [3, 1, 5, 2, 4],
        [6, 2, 2, 4, 4],
        precision: 4,
      );

      expect(outOfOrder.xi, [1, 2, 3, 4, 5]);
      expect(outOfOrder.ni, [2, 4, 6, 4, 2]);
      expect(outOfOrder.median, 3);
      expect(outOfOrder.weightedMean, closeTo(3.0, 1e-9));
    });

    test('merges rows sharing the same Xi by summing their Ni', () {
      final merged = computeDiscreteStats([2, 1, 2], [3, 5, 4]);

      expect(merged.xi, [1, 2]);
      expect(merged.ni, [5, 7]);
    });

    test('flags a unique mode', () {
      expect(result.isModeUnique, true);
      expect(result.modes, [3]);
    });

    test('reports every Xi tied for the highest effectif when the mode is not unique', () {
      final bimodal = computeDiscreteStats([1, 2, 3, 4], [5, 2, 5, 1]);

      expect(bimodal.isModeUnique, false);
      expect(bimodal.modes, [1, 3]);
      expect(bimodal.mode, 1);
    });

    test('flags correlation as undefined when every Ni is identical', () {
      // All Ni equal -> zero variance for Ni -> the correlation formula's
      // denominator is 0, so covariance/(0*x) is 0/0 (NaN), not an exception.
      final flatNi = computeDiscreteStats([1, 2, 3, 4], [5, 5, 5, 5]);

      expect(flatNi.correlation.isNaN, true);
      expect(flatNi.isCorrelationDefined, false);
    });

    test('flags coefficient of variation as undefined when the weighted mean is zero', () {
      // Symmetric around 0 with equal Ni -> weighted mean is 0, so
      // (stdDev / 0) * 100 is Infinity, not an exception.
      final zeroMean = computeDiscreteStats([-2, 0, 2], [1, 1, 1]);

      expect(zeroMean.weightedMean, 0);
      expect(zeroMean.coefficientOfVariation.isFinite, false);
      expect(zeroMean.isCoefficientOfVariationDefined, false);
    });

    test('picks the class whose cumulative effectif exceeds N/2 on an exact boundary, not an average', () {
      // xi 1..4, ni all 1 (total effectif 4, threshold = 2). The cumulative
      // effectif hits exactly 2 at xi=2 -- matching the app's own course
      // documentation ("la variable ayant l'effectif cumulé croissant
      // directement supérieur à 1/2*sum(Ni)"), the median is xi=3 (the first
      // class *strictly above* the threshold), not the average of 2 and 3.
      final boundary = computeDiscreteStats([1, 2, 3, 4], [1, 1, 1, 1]);
      expect(boundary.median, 3);
    });
  });

  group('computeDiscreteStats variance precision', () {
    /// Two-pass population variance straight from the definition, as an
    /// independent reference.
    double referenceVariance(List<double> xi, List<double> ni) {
      final total = ni.reduce((a, b) => a + b);
      var mean = 0.0;
      for (var i = 0; i < xi.length; i++) {
        mean += xi[i] * ni[i] / total;
      }
      var sum = 0.0;
      for (var i = 0; i < xi.length; i++) {
        sum += ni[i] * (xi[i] - mean) * (xi[i] - mean);
      }
      return sum / total;
    }

    // Large, tightly clustered Xi made Σxi²ni/Σni − x̄² (with x̄ already
    // rounded) cancel catastrophically: 1000/1001 came out as -0.445 (NaN
    // standard deviation) and 123456..123458 as 83.11 instead of ~0.806.
    final cases = <(List<double>, List<double>)>[
      ([1000, 1001], [1, 2]),
      ([123456, 123457, 123458], [3, 1, 2]),
      ([1e6, 1e6 + 0.5, 1e6 + 1], [7, 3, 5]),
      ([-5000.25, -4999.75, -4999.5], [2, 9, 4]),
    ];

    for (final (xi, ni) in cases) {
      test('matches the reference for xi=$xi ni=$ni', () {
        final result = computeDiscreteStats(xi, ni);
        final expected = referenceVariance(xi, ni);

        expect(result.variance, closeTo(expected, 1e-3));
        expect(result.variance, greaterThanOrEqualTo(0));
        expect(result.standardDeviation.isNaN, isFalse);
        expect(result.isCoefficientOfVariationDefined, isTrue);
      });
    }
  });

  group('computeDiscreteStats midpoint on exact tie', () {
    test('keeps the course rule and exposes the midpoint when N+ hits ΣNi/2 exactly', () {
      // N+ = 1, 2 and ΣNi/2 = 1: the course's "directly above" rule gives
      // Me = 2; averaging the two central values would give 1.5.
      final r = computeDiscreteStats([1, 2], [1, 1]);

      expect(r.median, 2);
      expect(r.medianMidpoint, 1.5);
    });

    test('exposes the midpoint for quartiles and deciles too', () {
      // N+ = 1..10 with ΣNi = 10: ΣNi/4 = 2.5 (no tie), 3ΣNi/4 = 7.5 (no
      // tie), ΣNi/10 = 1 and 9ΣNi/10 = 9 (both ties).
      final r = computeDiscreteStats(
        [for (var i = 1; i <= 10; i++) i.toDouble()],
        List.filled(10, 1),
      );

      expect(r.firstQuartileMidpoint, isNull);
      expect(r.thirdQuartileMidpoint, isNull);
      expect(r.firstDecile, 2);
      expect(r.firstDecileMidpoint, 1.5);
      expect(r.ninthDecile, 10);
      expect(r.ninthDecileMidpoint, 9.5);
    });

    test('is null when no cumulative effectif lands exactly on the threshold', () {
      final r = computeDiscreteStats([1, 2, 3], [1, 1, 1]);

      expect(r.median, 2);
      expect(r.medianMidpoint, isNull);
    });
  });
}
