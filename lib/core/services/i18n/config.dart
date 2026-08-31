abstract class I18nConfig {
  static List<LangItem> langItems = [
    LangItem(
      label: {
        'fr': 'Français',
        'en': 'French',
        'de': 'Französisch',
        'es': 'Francés',
        'pt': 'Francês',
      },
      code: 'fr',
    ),
    LangItem(
      label: {
        'fr': 'Anglais',
        'en': 'English',
        'de': 'Englisch',
        'es': 'Inglés',
        'pt': 'Inglês',
      },
      code: 'en',
    ),
    LangItem(
      label: {
        'fr': 'Allemand',
        'en': 'German',
        'de': 'Deutsch',
        'es': 'Alemán',
        'pt': 'Alemão',
      },
      code: 'de',
    ),
    LangItem(
      label: {
        'fr': 'Espagnol',
        'en': 'Spanish',
        'de': 'Spanisch',
        'es': 'Español',
        'pt': 'Espanhol',
      },
      code: 'es',
    ),
    LangItem(
      label: {
        'fr': 'Portugais',
        'en': 'Portuguese',
        'de': 'Portugiesisch',
        'es': 'Portugués',
        'pt': 'Português',
      },
      code: 'pt',
    ),
  ];
}

class LangItem {
  Map<String, String> label;
  String code;

  LangItem({required this.label, required this.code});
}
