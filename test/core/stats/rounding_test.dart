import 'package:flutter_starter/core/stats/rounding.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('arrondi', () {
    test('rounds half up for positive values', () {
      expect(arrondi(2.345, 2), 2.35);
      expect(arrondi(2.344, 2), 2.34);
    });

    test('rounds half away from zero for negative values', () {
      expect(arrondi(-2.345, 2), -2.35);
      expect(arrondi(-2.344, 2), -2.34);
    });

    test('rounds to zero decimals', () {
      expect(arrondi(4.5, 0), 5.0);
      expect(arrondi(-4.5, 0), -5.0);
    });

    test('leaves already-precise values unchanged', () {
      expect(arrondi(3.0, 3), 3.0);
    });

    test('rounds values whose binary representation falls just short of the half', () {
      // 1.005 and 0.145 are actually stored as ~1.00499999999999989 and
      // ~0.144999999999999990 -- without the epsilon nudge these would
      // truncate down to 1.0/0.14 instead of rounding up.
      expect(arrondi(1.005, 2), 1.01);
      expect(arrondi(0.145, 2), 0.15);
    });
  });

  group('noZero', () {
    test('drops the trailing .0 for whole numbers', () {
      expect(noZero(3.0), '3');
      expect(noZero(-5.0), '-5');
    });

    test('keeps the decimal part for fractional values', () {
      expect(noZero(3.5), '3.5');
    });
  });
}
