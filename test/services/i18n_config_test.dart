import 'package:descriptive_statistics/core/services/i18n/config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('I18nConfig.langItems', () {
    test('lists all 5 supported locales with codes and labels', () {
      final codes = I18nConfig.langItems.map((item) => item.code).toList();
      expect(codes, ['fr', 'en', 'de', 'es', 'pt']);

      final fr = I18nConfig.langItems.firstWhere((item) => item.code == 'fr');
      expect(fr.label['fr'], 'Français');
      expect(fr.label['en'], 'French');
      expect(fr.label['de'], 'Französisch');
      expect(fr.label['es'], 'Francés');
      expect(fr.label['pt'], 'Francês');

      final en = I18nConfig.langItems.firstWhere((item) => item.code == 'en');
      expect(en.label['fr'], 'Anglais');
      expect(en.label['en'], 'English');
    });

    test('every language item has a label for all 5 locale codes', () {
      const localeCodes = ['fr', 'en', 'de', 'es', 'pt'];
      for (final item in I18nConfig.langItems) {
        for (final code in localeCodes) {
          expect(item.label.containsKey(code), isTrue, reason: '${item.code} is missing a label for $code');
        }
      }
    });
  });
}
