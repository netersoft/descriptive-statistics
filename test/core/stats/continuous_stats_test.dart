import 'package:flutter_starter/core/stats/continuous_stats.dart';
import 'package:flutter_starter/core/stats/stats_exceptions.dart';
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

    test('computes the weighted and simple means', () {
      expect(result.weightedMean, closeTo(17.5, 1e-9));
      expect(result.simpleMean, closeTo(5.0, 1e-9));
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

    test('looks deciles up at the class midpoint (not interpolated)', () {
      expect(result.firstDecile, 5);
      expect(result.ninthDecile, 35);
    });

    test('computes variance, standard deviation, and standard error', () {
      expect(result.variance, closeTo(98.75, 1e-3));
      expect(result.standardDeviation, closeTo(9.9373, 1e-3));
      expect(result.standardError, closeTo(4.9686, 1e-3));
    });

    test('computes covariance and correlation', () {
      expect(result.covariance, closeTo(-16.6667, 1e-3));
      expect(result.correlation, closeTo(-0.5977, 1e-3));
    });

    test('computes the range and flags heterogeneity', () {
      expect(result.range, 40);
      expect(result.isHomogeneous, false);
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

    test('throws on a negative class width', () {
      expect(
        () => computeContinuousStats([0, 20], [10, 15], [5, 5]),
        throwsA(
          isA<StatsInputException>().having((e) => e.reason, 'reason', StatsErrorReason.negativeClassWidth),
        ),
      );
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
}
