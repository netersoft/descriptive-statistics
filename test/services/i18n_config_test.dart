import 'package:flutter_starter/core/services/i18n/config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('I18nConfig.langItems', () {
    test('lists French and English with codes and labels', () {
      final codes = I18nConfig.langItems.map((item) => item.code).toList();
      expect(codes, ['fr', 'en']);

      final fr = I18nConfig.langItems.firstWhere((item) => item.code == 'fr');
      expect(fr.label['fr'], 'Français');
      expect(fr.label['en'], 'French');

      final en = I18nConfig.langItems.firstWhere((item) => item.code == 'en');
      expect(en.label['fr'], 'Anglais');
      expect(en.label['en'], 'English');
    });
  });
}
