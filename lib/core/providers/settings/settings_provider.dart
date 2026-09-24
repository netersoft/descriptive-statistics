import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../enums/app_brightness.dart';
import '../../helpers/router/navigation_helper.dart';
import '../../routes/app_route.dart';
import '../../services/di/locator.dart';
import '../../services/i18n/translations.g.dart';
import '../../services/shared_preferences/keys.dart';
import '../../services/shared_preferences/service.dart';
import '../../tools/constants/chart_options.dart';

part 'settings_provider.g.dart';

// Resolved on each use rather than cached in a final global, so it always
// matches the locator's current registration (tests re-register it).
NavigationHelper get _navigationHelper => locator<NavigationHelper>();

const _playStoreUrl = 'https://play.google.com/store/apps/details?id=com.neteru.tixtat';

@Riverpod(keepAlive: true)
class Settings extends _$Settings {
  final SharedPreferencesService prefs = locator<SharedPreferencesService>();

  /// Loads every setting from storage once; the setters below then keep
  /// storage and this state in sync, so anything watching the provider
  /// (the Settings screen's labels, the calculators' charts and rounding)
  /// updates as soon as a setting changes.
  @override
  SettingsState build() => SettingsState(
    decimalPrecision: prefs.getInt(PrefKeys.decimalPrecision, defaultValue: 3) ?? 3,
    appBrightness: prefs.getString(PrefKeys.brightness, defaultValue: AppBrightness.system.name) ?? AppBrightness.system.name,
    discreteChartTypes: _readTypes(PrefKeys.discreteChartTypes, QuantitativeChartType.values),
    continuousChartTypes: _readTypes(PrefKeys.continuousChartTypes, QuantitativeChartType.values),
    qualitativeChartTypes: _readTypes(PrefKeys.qualitativeChartTypes, QualitativeChartType.values),
  );

  Set<T> _readTypes<T extends Enum>(String key, List<T> values) {
    final stored = prefs.getListString(key);
    if (stored == null) return values.toSet();
    return stored.map(values.byName).toSet();
  }

  void _writeTypes(String key, Set<Enum> types) => prefs.setStringList(key, types.map((t) => t.name).toList());

  Future<void> shareApp() async {
    var ctx = _navigationHelper.navigatorKey.currentContext;
    if (ctx == null) return;

    final box = ctx.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: '${t.appNameAlt}:\n\n$_playStoreUrl\n\n',
        subject: t.share,
        sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  /// Opens the app's Play Store listing directly.
  ///
  /// Google explicitly recommends against wiring the native in-app review
  /// flow (`requestReview()`) to an always-available menu action like this
  /// one: it silently no-ops once the user's review quota is spent or the
  /// conditions aren't met, with no way for the caller to detect that --
  /// verified on-device, where Play Core logs a successful request yet shows
  /// nothing. A menu item the user tapped on purpose should always do
  /// something visible, so redirect straight to the store instead.
  /// https://developer.android.com/guide/playcore/in-app-review#when-to-request
  Future<void> rateApp() async {
    final uri = Uri.parse(_playStoreUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> changeLanguage(String newValue) async {
    final navigator = _navigationHelper.navigatorKey.currentState;
    // Persisted so it survives a cold start -- bootstrap otherwise falls
    // back to the device locale (see applySavedOrDeviceLocale).
    await prefs.setString(PrefKeys.language, newValue);
    await LocaleSettings.setLocaleRaw(newValue);

    try {
      _navigationHelper.go(const SettingsRoute().location);
      if (navigator != null && navigator.mounted) {
        Phoenix.rebirth(navigator.context);
      }
    } catch (e) {
      _navigationHelper.pushReplacement(const RedirectionRoute().location);
    }
  }

  void setDecimalPrecision(int precision) {
    prefs.setInt(PrefKeys.decimalPrecision, precision);
    state = state.copyWith(decimalPrecision: precision);
  }

  void setAppBrightness(String appBrightness, {bool relaunch = true}) {
    prefs.setString(PrefKeys.brightness, appBrightness);
    state = state.copyWith(appBrightness: appBrightness);

    // The theme is built once from storage (AppTheme.isLight), so switching
    // it still takes a full rebuild of the app.
    if (relaunch) {
      try {
        _navigationHelper.go(const SettingsRoute().location);
        var ctx = _navigationHelper.navigatorKey.currentContext;
        if (ctx != null) Phoenix.rebirth(ctx);
      } catch (e) {
        _navigationHelper.pushReplacement(const RedirectionRoute().location);
      }
    }
  }

  void setDiscreteChartTypes(Set<QuantitativeChartType> types) {
    _writeTypes(PrefKeys.discreteChartTypes, types);
    state = state.copyWith(discreteChartTypes: types);
  }

  void setContinuousChartTypes(Set<QuantitativeChartType> types) {
    _writeTypes(PrefKeys.continuousChartTypes, types);
    state = state.copyWith(continuousChartTypes: types);
  }

  void setQualitativeChartTypes(Set<QualitativeChartType> types) {
    _writeTypes(PrefKeys.qualitativeChartTypes, types);
    state = state.copyWith(qualitativeChartTypes: types);
  }
}

class SettingsState {
  /// Decimal places calculator results are rounded to.
  final int decimalPrecision;

  /// An [AppBrightness] name.
  final String appBrightness;

  final Set<QuantitativeChartType> discreteChartTypes;
  final Set<QuantitativeChartType> continuousChartTypes;
  final Set<QualitativeChartType> qualitativeChartTypes;

  const SettingsState({
    required this.decimalPrecision,
    required this.appBrightness,
    required this.discreteChartTypes,
    required this.continuousChartTypes,
    required this.qualitativeChartTypes,
  });

  SettingsState copyWith({
    int? decimalPrecision,
    String? appBrightness,
    Set<QuantitativeChartType>? discreteChartTypes,
    Set<QuantitativeChartType>? continuousChartTypes,
    Set<QualitativeChartType>? qualitativeChartTypes,
  }) => SettingsState(
    decimalPrecision: decimalPrecision ?? this.decimalPrecision,
    appBrightness: appBrightness ?? this.appBrightness,
    discreteChartTypes: discreteChartTypes ?? this.discreteChartTypes,
    continuousChartTypes: continuousChartTypes ?? this.continuousChartTypes,
    qualitativeChartTypes: qualitativeChartTypes ?? this.qualitativeChartTypes,
  );
}
