import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter/core/enums/app_brightness.dart';
import 'package:flutter_starter/core/providers/settings/settings_provider.dart';
import 'package:flutter_starter/core/services/i18n/translations.g.dart';
import 'package:flutter_starter/core/services/shared_preferences/keys.dart';
import 'package:flutter_starter/core/tools/constants/chart_options.dart';
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
    test('appBrightness defaults to system when unset', () {
      when(
        () => mockPrefs.getString(any(), defaultValue: any(named: 'defaultValue')),
      ).thenReturn(AppBrightness.system.name);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final settings = container.read(settingsProvider);
      expect(settings.appBrightness, AppBrightness.system.name);
    });

    test('appBrightness returns the stored value', () {
      when(
        () => mockPrefs.getString(any(), defaultValue: any(named: 'defaultValue')),
      ).thenReturn(AppBrightness.dark.name);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final settings = container.read(settingsProvider);
      expect(settings.appBrightness, AppBrightness.dark.name);
    });

    test('setAppBrightness persists the value without relaunching', () {
      when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(settingsProvider.notifier).setAppBrightness(AppBrightness.light.name, relaunch: false);

      expect(container.read(settingsProvider).appBrightness, AppBrightness.light.name);
      verify(() => mockPrefs.setString(PrefKeys.brightness, AppBrightness.light.name)).called(1);
      verifyNever(() => mockNav.go(any()));
    });

    test('changeLanguage persists the picked language so it survives a restart', () async {
      when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);
      // No live navigator in a unit test: the relaunch step is skipped.
      when(() => mockNav.navigatorKey).thenReturn(GlobalKey<NavigatorState>());

      final container = ProviderContainer();
      addTearDown(container.dispose);
      addTearDown(() => LocaleSettings.setLocaleRaw('fr'));

      await container.read(settingsProvider.notifier).changeLanguage('de');

      verify(() => mockPrefs.setString(PrefKeys.language, 'de')).called(1);
      expect(LocaleSettings.currentLocale, AppLocale.de);
    });

    test('decimalPrecision defaults to 3 when unset', () {
      when(
        () => mockPrefs.getInt(any(), defaultValue: any(named: 'defaultValue')),
      ).thenReturn(3);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final settings = container.read(settingsProvider);
      expect(settings.decimalPrecision, 3);
    });

    test('setDecimalPrecision persists the value and updates the state without navigating', () {
      when(() => mockPrefs.setInt(any(), any())).thenAnswer((_) async => true);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(settingsProvider.notifier).setDecimalPrecision(5);

      verify(() => mockPrefs.setInt(PrefKeys.decimalPrecision, 5)).called(1);
      expect(container.read(settingsProvider).decimalPrecision, 5);
      verifyNever(() => mockNav.go(any()));
    });

    test('discreteChartTypes defaults to all types when unset', () {
      when(() => mockPrefs.getListString(any())).thenReturn(null);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final settings = container.read(settingsProvider);
      expect(settings.discreteChartTypes, QuantitativeChartType.values.toSet());
    });

    test('continuousChartTypes returns the stored subset', () {
      when(() => mockPrefs.getListString(any())).thenReturn(['bar']);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final settings = container.read(settingsProvider);
      expect(settings.continuousChartTypes, {QuantitativeChartType.bar});
    });

    test('setDiscreteChartTypes persists the selected type names', () {
      when(() => mockPrefs.setStringList(any(), any())).thenAnswer((_) async => true);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(settingsProvider.notifier).setDiscreteChartTypes({QuantitativeChartType.line});

      verify(() => mockPrefs.setStringList(PrefKeys.discreteChartTypes, ['line'])).called(1);
      expect(container.read(settingsProvider).discreteChartTypes, {QuantitativeChartType.line});
    });

    test('qualitativeChartTypes defaults to all types when unset', () {
      when(() => mockPrefs.getListString(any())).thenReturn(null);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final settings = container.read(settingsProvider);
      expect(settings.qualitativeChartTypes, QualitativeChartType.values.toSet());
    });

    test('setQualitativeChartTypes persists the selected type names', () {
      when(() => mockPrefs.setStringList(any(), any())).thenAnswer((_) async => true);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(settingsProvider.notifier).setQualitativeChartTypes({QualitativeChartType.pie});

      verify(() => mockPrefs.setStringList(PrefKeys.qualitativeChartTypes, ['pie'])).called(1);
    });
  });
}
