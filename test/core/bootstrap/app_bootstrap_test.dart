import 'package:flutter_starter/core/bootstrap/app_bootstrap.dart';
import 'package:flutter_starter/core/services/i18n/translations.g.dart';
import 'package:flutter_starter/core/services/shared_preferences/keys.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSharedPreferencesService prefs;

  setUp(() async {
    prefs = MockSharedPreferencesService();
    // flutter_test reports en_US as the device locale.
    await LocaleSettings.setLocaleRaw('fr');
  });

  tearDown(() => LocaleSettings.setLocaleRaw('fr'));

  group('applySavedOrDeviceLocale', () {
    test('restores the language picked in Settings instead of the device one', () async {
      when(() => prefs.getString(PrefKeys.language)).thenReturn('de');

      await applySavedOrDeviceLocale(prefs);

      expect(LocaleSettings.currentLocale, AppLocale.de);
    });

    test('follows the device locale when no language was picked', () async {
      when(() => prefs.getString(PrefKeys.language)).thenReturn(null);

      await applySavedOrDeviceLocale(prefs);

      expect(LocaleSettings.currentLocale, AppLocale.en);
    });

    test('follows the device locale when the saved code is not supported', () async {
      when(() => prefs.getString(PrefKeys.language)).thenReturn('xx');

      await applySavedOrDeviceLocale(prefs);

      expect(LocaleSettings.currentLocale, AppLocale.en);
    });
  });
}
