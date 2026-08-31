import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter/core/enums/app_brightness.dart';
import 'package:flutter_starter/core/providers/settings/settings_provider.dart';
import 'package:flutter_starter/core/services/shared_preferences/keys.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_utils.dart';

void main() {
  late MockSharedPreferencesService mockPrefs;
  late MockNavigationHelper mockNav;

  setUp(() async {
    mockPrefs = MockSharedPreferencesService();
    mockNav = MockNavigationHelper();

    await setupTestLocator(
      sharedPreferencesService: mockPrefs,
      navigationHelper: mockNav,
    );
  });

  tearDown(teardownTestLocator);

  group('SettingsProvider', () {
    test('getAppBrightness defaults to system when unset', () {
      when(
        () => mockPrefs.getString(any(), defaultValue: any(named: 'defaultValue')),
      ).thenReturn(AppBrightness.system.name);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final settings = container.read(settingsProvider.notifier);
      expect(settings.getAppBrightness(), AppBrightness.system.name);
    });

    test('getAppBrightness returns the stored value', () {
      when(
        () => mockPrefs.getString(any(), defaultValue: any(named: 'defaultValue')),
      ).thenReturn(AppBrightness.dark.name);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final settings = container.read(settingsProvider.notifier);
      expect(settings.getAppBrightness(), AppBrightness.dark.name);
    });

    test('setAppBrightness persists the value without relaunching', () {
      when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(settingsProvider.notifier).setAppBrightness(AppBrightness.light.name, relaunch: false);

      verify(() => mockPrefs.setString(PrefKeys.brightness, AppBrightness.light.name)).called(1);
      verifyNever(() => mockNav.go(any()));
    });

    test('getDecimalPrecision defaults to 3 when unset', () {
      when(
        () => mockPrefs.getInt(any(), defaultValue: any(named: 'defaultValue')),
      ).thenReturn(3);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final settings = container.read(settingsProvider.notifier);
      expect(settings.getDecimalPrecision(), 3);
    });

    test('setDecimalPrecision persists the value and remounts the settings screen', () {
      when(() => mockPrefs.setInt(any(), any())).thenAnswer((_) async => true);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(settingsProvider.notifier).setDecimalPrecision(5);

      verify(() => mockPrefs.setInt(PrefKeys.decimalPrecision, 5)).called(1);
      verify(() => mockNav.go(any())).called(1);
    });
  });
}
