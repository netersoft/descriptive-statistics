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
}
