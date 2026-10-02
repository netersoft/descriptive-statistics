import 'package:descriptive_statistics/core/stats/qualitative_stats.dart';
import 'package:descriptive_statistics/core/stats/stats_exceptions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeQualitativeStats', () {
    // Modalities A, B, A, C, B, A with values 10, 20, 15, 5, 10, 25.
    // A = 10+15+25 = 50, B = 20+10 = 30, C = 5. Total = 85.
    final result = computeQualitativeStats(
      ['A', 'B', 'A', 'C', 'B', 'A'],
      [10, 20, 15, 5, 10, 25],
      precision: 4,
    );

    test('aggregates values per modality in first-seen order', () {
      expect(result.modalities, ['A', 'B', 'C']);
      expect(result.effectifs, [50, 30, 5]);
      expect(result.total, 85);
    });

    test('computes frequencies summing to 100', () {
      expect(result.frequencies[0], closeTo(58.8235, 1e-3));
      expect(result.frequencies[1], closeTo(35.2941, 1e-3));
      expect(result.frequencies[2], closeTo(5.8824, 1e-3));
      expect(result.frequencies.reduce((a, b) => a + b), closeTo(100.0, 1e-2));
    });

    test('computes monotonically increasing cumulative effectifs and frequencies', () {
      expect(result.cumulativeEffectifs, [50, 80, 85]);
      expect(result.cumulativeFrequencies.last, closeTo(100.0, 1e-2));
      for (var i = 1; i < result.cumulativeEffectifs.length; i++) {
        expect(result.cumulativeEffectifs[i], greaterThanOrEqualTo(result.cumulativeEffectifs[i - 1]));
        expect(result.cumulativeFrequencies[i], greaterThanOrEqualTo(result.cumulativeFrequencies[i - 1]));
      }
    });

    test('finds the modality with the highest effectif', () {
      expect(result.modeModality, 'A');
      expect(result.isModeUnique, true);
      expect(result.modeModalities, ['A']);
    });

    test('reports every modality tied for the highest effectif when the mode is not unique', () {
      final bimodal = computeQualitativeStats(['A', 'B', 'C'], [10, 5, 10]);

      expect(bimodal.isModeUnique, false);
      expect(bimodal.modeModalities, ['A', 'C']);
      expect(bimodal.modeModality, 'A');
    });

    test('computes the mean of the aggregated effectifs', () {
      expect(result.mean, closeTo(85 / 3, 1e-3));
    });

    test('first modality seen wins ties', () {
      final tied = computeQualitativeStats(['X', 'Y'], [10, 10]);
      expect(tied.modeModality, 'X');
    });

    test('throws on mismatched lengths', () {
      expect(
        () => computeQualitativeStats(['A', 'B'], [1]),
        throwsA(
          isA<StatsInputException>().having((e) => e.reason, 'reason', StatsErrorReason.lengthMismatch),
        ),
      );
    });

    test('throws on insufficient data', () {
      expect(
        () => computeQualitativeStats(['A'], [1]),
        throwsA(
          isA<StatsInputException>().having((e) => e.reason, 'reason', StatsErrorReason.insufficientData),
        ),
      );
    });

    test('throws on a negative value', () {
      expect(
        () => computeQualitativeStats(['A', 'B'], [10, -1]),
        throwsA(
          isA<StatsInputException>().having((e) => e.reason, 'reason', StatsErrorReason.negativeEffectif),
        ),
      );
    });

    test('throws when every value is zero', () {
      expect(
        () => computeQualitativeStats(['A', 'B'], [0, 0]),
        throwsA(
          isA<StatsInputException>().having((e) => e.reason, 'reason', StatsErrorReason.zeroTotalEffectif),
        ),
      );
    });
  });
}
