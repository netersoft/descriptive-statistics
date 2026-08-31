import 'package:flutter_starter/core/services/i18n/translations.g.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocaleSettings', () {
    test('default locale is fr', () {
      expect(LocaleSettings.currentLocale, AppLocale.fr);
    });

    test('setLocaleRaw changes locale', () async {
      await LocaleSettings.setLocaleRaw('en');
      expect(LocaleSettings.currentLocale, AppLocale.en);

      await LocaleSettings.setLocaleRaw('fr');
      expect(LocaleSettings.currentLocale, AppLocale.fr);
    });

    test('setLocaleRaw supports German, Spanish, and Portuguese', () async {
      await LocaleSettings.setLocaleRaw('de');
      expect(LocaleSettings.currentLocale, AppLocale.de);

      await LocaleSettings.setLocaleRaw('es');
      expect(LocaleSettings.currentLocale, AppLocale.es);

      await LocaleSettings.setLocaleRaw('pt');
      expect(LocaleSettings.currentLocale, AppLocale.pt);

      await LocaleSettings.setLocaleRaw('fr');
    });

    test('translations reflect current locale', () async {
      await LocaleSettings.setLocaleRaw('fr');
      expect(t.language, 'Langue');

      await LocaleSettings.setLocaleRaw('en');
      expect(t.language, 'Language');

      await LocaleSettings.setLocaleRaw('de');
      expect(t.language, 'Sprache');

      await LocaleSettings.setLocaleRaw('es');
      expect(t.language, 'Idioma');

      await LocaleSettings.setLocaleRaw('pt');
      expect(t.language, 'Idioma');

      await LocaleSettings.setLocaleRaw('fr');
    });
  });
}
