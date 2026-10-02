import 'dart:ui';

import 'package:descriptive_statistics/core/tools/functions/color_functions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isColorDark', () {
    test('returns true for black', () {
      expect(isColorDark(const Color(0xff000000)), true);
    });

    test('returns false for white', () {
      expect(isColorDark(const Color(0xffffffff)), false);
    });

    test('returns true for a dark color like onyx', () {
      expect(isColorDark(const Color(0xff353839)), true);
    });
  });
}
