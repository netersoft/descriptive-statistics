import 'package:flutter/material.dart';
import 'package:flutter_starter/core/enums/app_brightness.dart';
import 'package:flutter_starter/view/themes/app_colors.dart';
import 'package:flutter_starter/view/themes/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_utils.dart';

void main() {
  // AppTheme.prefs is a `static final` bound to the locator on first access
  // and never rebound afterwards, so a single mock/registration is reused
  // for every test in this file -- only the stubbed return value changes.
  late MockSharedPreferencesService mockPrefs;

  setUpAll(() async {
    mockPrefs = MockSharedPreferencesService();
    await setupTestLocator(sharedPreferencesService: mockPrefs);
  });

  tearDownAll(teardownTestLocator);

  void stubBrightness(String value) {
    when(
      () => mockPrefs.getString(any(), defaultValue: any(named: 'defaultValue')),
    ).thenReturn(value);
  }

  group('AppTheme brightness-derived helpers', () {
    test('pickColor returns the light color when brightness is light', () {
      stubBrightness(AppBrightness.light.name);
      expect(
        AppTheme.pickColor(light: Colors.white, dark: Colors.black),
        Colors.white,
      );
    });

    test('pickColor returns the dark color when brightness is dark', () {
      stubBrightness(AppBrightness.dark.name);
      expect(
        AppTheme.pickColor(light: Colors.white, dark: Colors.black),
        Colors.black,
      );
    });

    test('getBgDefaultColor is white in light mode and blackRussian in dark mode', () {
      stubBrightness(AppBrightness.light.name);
      expect(AppTheme.getBgDefaultColor(), Colors.white);

      stubBrightness(AppBrightness.dark.name);
      expect(AppTheme.getBgDefaultColor(), AppColors.blackRussian);
    });

    test('getAppbarBgColor is primaryColor in light mode and raisinBlack in dark mode', () {
      stubBrightness(AppBrightness.light.name);
      expect(AppTheme.getAppbarBgColor(), AppTheme.primaryColor);

      stubBrightness(AppBrightness.dark.name);
      expect(AppTheme.getAppbarBgColor(), AppColors.raisinBlack);
    });

    test('getIconColor is primaryColor in light mode and accentColor in dark mode', () {
      stubBrightness(AppBrightness.light.name);
      expect(AppTheme.getIconColor(), AppTheme.primaryColor);

      stubBrightness(AppBrightness.dark.name);
      expect(AppTheme.getIconColor(), AppTheme.accentColor);
    });

    test('getTextColor is blackRussian in light mode and concrete in dark mode', () {
      stubBrightness(AppBrightness.light.name);
      expect(AppTheme.getTextColor(), AppColors.blackRussian);

      stubBrightness(AppBrightness.dark.name);
      expect(AppTheme.getTextColor(), AppColors.concrete);
    });

    test('pickByTheme returns the branch matching the current brightness', () {
      stubBrightness(AppBrightness.light.name);
      expect(AppTheme.pickByTheme(light: 'a', dark: 'b'), 'a');

      stubBrightness(AppBrightness.dark.name);
      expect(AppTheme.pickByTheme(light: 'a', dark: 'b'), 'b');
    });
  });

  group('AppTheme.getContentRelativeColor', () {
    test('returns white for the primary color', () {
      expect(AppTheme.getContentRelativeColor(AppTheme.primaryColor), Colors.white);
    });

    test('returns black for a light, non-primary color', () {
      expect(AppTheme.getContentRelativeColor(Colors.white), Colors.black);
    });

    test('returns white for a dark, non-primary color', () {
      expect(AppTheme.getContentRelativeColor(Colors.black), Colors.white);
    });
  });
}
