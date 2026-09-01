import 'package:flutter_starter/core/tools/functions/number_parsing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseDecimal', () {
    test('parses a plain integer', () {
      expect(parseDecimal('42'), 42.0);
    });

    test('parses a dot-decimal value', () {
      expect(parseDecimal('3.5'), 3.5);
    });

    test('parses a comma-decimal value, as fr/de/es/pt keyboards produce', () {
      expect(parseDecimal('3,5'), 3.5);
    });

    test('parses a signed comma-decimal value', () {
      expect(parseDecimal('-2,75'), -2.75);
    });

    test('trims surrounding whitespace', () {
      expect(parseDecimal('  4,2  '), 4.2);
    });

    test('returns null for invalid input', () {
      expect(parseDecimal('abc'), isNull);
      expect(parseDecimal('1,2,3'), isNull);
      expect(parseDecimal(''), isNull);
    });
  });

  group('decimalSeparatorForLocale', () {
    test('is a comma for fr/de/es/pt', () {
      for (final code in ['fr', 'de', 'es', 'pt']) {
        expect(decimalSeparatorForLocale(code), ',');
      }
    });

    test('is a dot for en', () {
      expect(decimalSeparatorForLocale('en'), '.');
    });
  });
}
