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
  @override
  SettingsState build() => const SettingsState();

  final SharedPreferencesService prefs = locator<SharedPreferencesService>();

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

  int getDecimalPrecision() => prefs.getInt(PrefKeys.decimalPrecision, defaultValue: 3) ?? 3;

  void setDecimalPrecision(int precision) {
    prefs.setInt(PrefKeys.decimalPrecision, precision);

    // Remounts SettingsScreen so its trailing label reflects the new value --
    // unlike brightness/language, this setting has no other visual effect,
    // so a full Phoenix.rebirth() isn't warranted.
    try {
      _navigationHelper.go(const SettingsRoute().location);
    } catch (e) {
      _navigationHelper.pushReplacement(const RedirectionRoute().location);
    }
  }

  String? getAppBrightness() => prefs.getString(
    PrefKeys.brightness,
    defaultValue: AppBrightness.system.name,
  );

  void setAppBrightness(String appBrightness, {bool relaunch = true}) {
    prefs.setString(PrefKeys.brightness, appBrightness);

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

  Set<QuantitativeChartType> getDiscreteChartTypes() => _getQuantitativeChartTypes(PrefKeys.discreteChartTypes);

  void setDiscreteChartTypes(Set<QuantitativeChartType> types) => _setChartTypes(PrefKeys.discreteChartTypes, types);

  Set<QuantitativeChartType> getContinuousChartTypes() => _getQuantitativeChartTypes(PrefKeys.continuousChartTypes);

  void setContinuousChartTypes(Set<QuantitativeChartType> types) => _setChartTypes(PrefKeys.continuousChartTypes, types);

  Set<QuantitativeChartType> _getQuantitativeChartTypes(String key) {
    final stored = prefs.getListString(key);
    if (stored == null) return QuantitativeChartType.values.toSet();
    return stored.map(QuantitativeChartType.values.byName).toSet();
  }

  Set<QualitativeChartType> getQualitativeChartTypes() {
    final stored = prefs.getListString(PrefKeys.qualitativeChartTypes);
    if (stored == null) return QualitativeChartType.values.toSet();
    return stored.map(QualitativeChartType.values.byName).toSet();
  }

  void setQualitativeChartTypes(Set<QualitativeChartType> types) => _setChartTypes(PrefKeys.qualitativeChartTypes, types);

  void _setChartTypes(String key, Set<Enum> types) => prefs.setStringList(key, types.map((t) => t.name).toList());
}

class SettingsState {
  final bool isLoading;

  const SettingsState({this.isLoading = false});

  SettingsState copyWith({bool? isLoading}) => SettingsState(isLoading: isLoading ?? this.isLoading);
}
