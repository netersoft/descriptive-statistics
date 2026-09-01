import 'package:flutter_starter/core/providers/calculators/calculator_types.dart';
import 'package:flutter_starter/core/stats/continuous_stats.dart';
import 'package:flutter_starter/core/stats/discrete_stats.dart';
import 'package:flutter_starter/core/stats/qualitative_stats.dart';
import 'package:flutter_starter/view/components/calculators/share_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildDiscreteShareText', () {
    final result = computeDiscreteStats([1, 2, 3, 4, 5], [2, 4, 6, 4, 2]);

    test('includes the raw series and only the selected sections', () {
      final text = buildDiscreteShareText(result, {StatOption.mean, StatOption.mode});

      expect(text, contains('Xi: 1, 2, 3, 4, 5'));
      expect(text, contains('Ni: 2, 4, 6, 4, 2'));
      expect(text, contains('X = 3'));
      expect(text, contains('Mo = 3'));
      expect(text, isNot(contains('Me =')));
    });

    test('lists every tied value for a non-unique mode', () {
      final bimodal = computeDiscreteStats([1, 2, 3, 4], [5, 2, 5, 1]);
      final text = buildDiscreteShareText(bimodal, {StatOption.mode});

      expect(text, contains('Mo = 1, 3'));
    });
  });

  group('buildContinuousShareText', () {
    final result = computeContinuousStats([0, 10, 20, 30], [10, 20, 30, 40], [5, 8, 4, 3]);

    test('includes the class bounds and only the selected sections', () {
      final text = buildContinuousShareText(result, [0, 10, 20, 30], [10, 20, 30, 40], {StatOption.mean});

      expect(text, contains('L1: 0, 10, 20, 30'));
      expect(text, contains('L2: 10, 20, 30, 40'));
      expect(text, contains('X = 17.5'));
      expect(text, isNot(contains('Mo =')));
    });
  });

  group('buildQualitativeShareText', () {
    final result = computeQualitativeStats(['A', 'B', 'A', 'C'], [10, 20, 15, 5]);

    test('includes the modalities/effectifs and only the selected sections', () {
      final text = buildQualitativeShareText(result, {QualitativeStatOption.mean, QualitativeStatOption.mode});

      expect(text, contains('A, B, C'));
      expect(text, contains('25, 20, 5'));
      expect(text, contains('Mo = A'));
    });

    test('lists every tied modality for a non-unique mode', () {
      final bimodal = computeQualitativeStats(['A', 'B', 'C'], [10, 5, 10]);
      final text = buildQualitativeShareText(bimodal, {QualitativeStatOption.mode});

      expect(text, contains('Mo = A, C'));
    });
  });
}
