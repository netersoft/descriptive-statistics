import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

import '../../enums/app_brightness.dart';
import '../../helpers/router/navigation_helper.dart';
import '../../routes/app_route.dart';
import '../../services/di/locator.dart';
import '../../services/i18n/translations.g.dart';
import '../../services/shared_preferences/keys.dart';
import '../../services/shared_preferences/service.dart';

part 'settings_provider.g.dart';

final _navigationHelper = locator<NavigationHelper>();

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

  Future<void> changeLanguage(String newValue) async {
    final navigator = _navigationHelper.navigatorKey.currentState;
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
}

class SettingsState {
  final bool isLoading;

  const SettingsState({this.isLoading = false});

  SettingsState copyWith({bool? isLoading}) => SettingsState(isLoading: isLoading ?? this.isLoading);
}
