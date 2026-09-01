import 'dart:math' as math;

import 'package:flutter_starter/core/providers/calculators/calculator_types.dart';
import 'package:flutter_starter/core/stats/continuous_stats.dart';
import 'package:flutter_starter/core/stats/rounding.dart';
import 'package:flutter_starter/view/components/calculators/continuous_explanation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildContinuousExplanationHtml', () {
    const l1 = [0.0, 10.0, 20.0];
    const l2 = [10.0, 20.0, 30.0];
    const ni = [3.0, 5.0, 2.0];
    final r = computeContinuousStats(l1, l2, ni, precision: 6);

    test('rounds the covariance-sum and standard-deviation intermediates to the requested precision, not a hardcoded one', () {
      // Independently recomputed with the exact same logic the builder
      // uses internally, so this fails if the builder ever hardcodes a
      // precision instead of honoring the one it's given.
      final n = r.xi.length;
      final xMean = r.xi.reduce((a, b) => a + b) / n;
      final yMean = r.ni.reduce((a, b) => a + b) / n;
      var covarianceSum = 0.0;
      var xSquares = 0.0;
      var ySquares = 0.0;
      for (var i = 0; i < n; i++) {
        final v2 = r.xi[i] - xMean;
        final v1 = r.ni[i] - yMean;
        covarianceSum += v2 * v1;
        xSquares += v2 * v2;
        ySquares += v1 * v1;
      }
      final xDeviation = math.sqrt(xSquares / (n - 1));
      final yDeviation = math.sqrt(ySquares / (n - 1));

      for (final precision in [1, 6]) {
        final html = buildContinuousExplanationHtml(r, l1, l2, {StatOption.covariance}, precision);

        // French (the default test locale) displays decimals with a comma.
        expect(html, contains(noZero(arrondi(covarianceSum, precision), decimalSeparator: ',')));
        expect(html, contains(noZero(arrondi(xDeviation, precision), decimalSeparator: ',')));
        expect(html, contains(noZero(arrondi(yDeviation, precision), decimalSeparator: ',')));
      }
    });

    test('re-rounds ΣXiNi/ΣXi²Ni before display instead of showing raw floating-point sums', () {
      final xiniSum = arrondi(r.xini.reduce((a, b) => a + b), 6);
      final xi2niSum = arrondi(r.xi2ni.reduce((a, b) => a + b), 6);

      final html = buildContinuousExplanationHtml(r, l1, l2, {StatOption.mean, StatOption.variance}, 6);

      expect(html, contains(noZero(xiniSum, decimalSeparator: ',')));
      expect(html, contains(noZero(xi2niSum, decimalSeparator: ',')));
    });

    test('labels the modal/median class from the same l1/l2 arrays the result was computed from', () {
      final html = buildContinuousExplanationHtml(r, l1, l2, {}, 6);

      expect(html, contains('${noZero(l1[r.modalClassIndex])} - ${noZero(l2[r.modalClassIndex])}'));
      expect(html, contains('${noZero(l1[r.medianClassIndex])} - ${noZero(l2[r.medianClassIndex])}'));
    });
  });
}
