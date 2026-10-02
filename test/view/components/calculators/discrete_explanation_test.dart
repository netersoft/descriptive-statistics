import 'dart:math' as math;

import 'package:descriptive_statistics/core/providers/calculators/calculator_types.dart';
import 'package:descriptive_statistics/core/stats/discrete_stats.dart';
import 'package:descriptive_statistics/core/stats/rounding.dart';
import 'package:descriptive_statistics/view/components/calculators/discrete_explanation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildDiscreteExplanationHtml', () {
    // Asymmetric so covariance/correlation are non-trivial, non-round
    // numbers -- needed to actually distinguish rounding to different
    // precisions below.
    final r = computeDiscreteStats([1, 2, 3], [1, 2, 7], precision: 6);

    test('rounds the covariance-sum and standard-deviation intermediates to the precision the result was computed with, not a hardcoded one', () {
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
        final html = buildDiscreteExplanationHtml(computeDiscreteStats([1, 2, 3], [1, 2, 7], precision: precision), {StatOption.covariance});

        // French (the default test locale) displays decimals with a comma.
        expect(html, contains(noZero(arrondi(covarianceSum, precision), decimalSeparator: ',')));
        expect(html, contains(noZero(arrondi(xDeviation, precision), decimalSeparator: ',')));
        expect(html, contains(noZero(arrondi(yDeviation, precision), decimalSeparator: ',')));
      }
    });

    test('re-rounds ΣXiNi/ΣXi²Ni before display instead of showing raw floating-point sums', () {
      final xiniSum = arrondi(r.xini.reduce((a, b) => a + b), 6);
      final xi2niSum = arrondi(r.xi2ni.reduce((a, b) => a + b), 6);

      final html = buildDiscreteExplanationHtml(r, {StatOption.mean, StatOption.variance});

      expect(html, contains(noZero(xiniSum, decimalSeparator: ',')));
      expect(html, contains(noZero(xi2niSum, decimalSeparator: ',')));
    });

    test('states the quantile convention once and shows the midpoint alternative on an exact tie', () {
      final tie = computeDiscreteStats([1, 2], [1, 1]);

      final html = buildDiscreteExplanationHtml(tie, {StatOption.median, StatOption.quartiles});

      expect(RegExp('Convention utilisée').allMatches(html).length, 1);
      expect(html, contains('on obtiendrait Me = 1,5'));
    });

    test('shows the convention note in the quartiles section when the median is not selected', () {
      // ΣNi = 3: no N+ (1, 2, 3) lands exactly on 0.3, 0.75, 2.25 or 2.7.
      final noTie = computeDiscreteStats([1, 2, 3], [1, 1, 1]);

      final html = buildDiscreteExplanationHtml(noTie, {StatOption.quartiles});

      expect(html, contains('Convention utilisée'));
      expect(html, contains('D1 = '));
      expect(html, contains('D9 = '));
      expect(html, isNot(contains('on obtiendrait')));
    });
  });
}
