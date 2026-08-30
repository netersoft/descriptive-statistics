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
