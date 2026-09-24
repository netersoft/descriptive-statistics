import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../services/di/locator.dart';
import '../services/i18n/translations.g.dart';
import '../services/shared_preferences/keys.dart';
import '../services/shared_preferences/service.dart';

class AppBootstrapConfig {
  final String envFileName;
  final bool preserveNativeSplash;
  final bool skipBindingInit;

  const AppBootstrapConfig({
    this.envFileName = '.env',
    this.preserveNativeSplash = true,
    this.skipBindingInit = false,
  });
}

Future<void> bootstrapApp({
  AppBootstrapConfig config = const AppBootstrapConfig(),
}) async {
  final WidgetsBinding widgetsBinding = config.skipBindingInit ? WidgetsBinding.instance : WidgetsFlutterBinding.ensureInitialized();

  if (config.preserveNativeSplash) {
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  }

  GoRouter.optionURLReflectsImperativeAPIs = true;

  await dotenv.load(fileName: config.envFileName);

  await Hive.initFlutter();

  await setupLocator();

  await applySavedOrDeviceLocale(locator<SharedPreferencesService>());
}

/// Restores the language picked in Settings, or follows the device locale
/// when none was picked (or the saved code is no longer supported).
Future<void> applySavedOrDeviceLocale(SharedPreferencesService prefs) async {
  final saved = prefs.getString(PrefKeys.language);
  if (saved != null && AppLocale.values.any((locale) => locale.languageCode == saved)) {
    await LocaleSettings.setLocaleRaw(saved);
  } else {
    await LocaleSettings.useDeviceLocale();
  }
}
