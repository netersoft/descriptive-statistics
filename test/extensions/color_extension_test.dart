import 'dart:ui';

import 'package:descriptive_statistics/core/extensions/color_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ColorX.fromHex', () {
    test('parses a 6-digit hex string with a leading #', () {
      final color = ColorX.fromHex('#009ee3');
      expect(color.toARGB32(), 0xff009ee3);
    });

    test('parses a 6-digit hex string without a leading #', () {
      final color = ColorX.fromHex('353839');
      expect(color.toARGB32(), 0xff353839);
    });

    test('parses an 8-digit ARGB hex string as-is', () {
      final color = ColorX.fromHex('80009ee3');
      expect(color.toARGB32(), 0x80009ee3);
    });
  });

  group('ColorX.isValidHex', () {
    test('accepts 3, 6, and 8 digit hex codes with or without #', () {
      expect(ColorX.isValidHex('#fff'), true);
      expect(ColorX.isValidHex('009ee3'), true);
      expect(ColorX.isValidHex('#80009ee3'), true);
    });

    test('rejects malformed hex codes', () {
      expect(ColorX.isValidHex('not-a-color'), false);
      expect(ColorX.isValidHex('#12345'), false);
    });
  });

  group('ColorX.toHex', () {
    test('round-trips a fully opaque color with a leading #', () {
      const color = Color(0xff009ee3);
      expect(color.toHex(), '#ff009ee3');
    });

    test('omits the leading # when requested', () {
      const color = Color(0xff009ee3);
      expect(color.toHex(leadingHashSign: false), 'ff009ee3');
    });
  });
}
