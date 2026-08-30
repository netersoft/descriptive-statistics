import 'package:flutter_starter/core/stats/discrete_stats.dart';
import 'package:flutter_starter/core/stats/stats_exceptions.dart';
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
  });
}
