import 'package:descriptive_statistics/core/services/i18n/translations.g.dart';
import 'package:descriptive_statistics/view/components/tutorial/tutorial_steps.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tutorialSteps', () {
    test('resolves the matching image folder for each supported locale', () {
      for (final locale in ['fr', 'en', 'de', 'es', 'pt']) {
        final steps = tutorialSteps(locale);
        expect(steps, hasLength(4));
        for (var i = 0; i < steps.length; i++) {
          expect(steps[i].imageAsset, 'assets/images/tutorial/$locale/tuto_${i + 1}.png');
        }
      }
    });

    test('falls back to en for an unsupported language code', () {
      final steps = tutorialSteps('it');
      expect(steps.first.imageAsset, 'assets/images/tutorial/en/tuto_1.png');
    });

    test('text resolves the right translation per locale', () async {
      expect(tutorialSteps('fr').first.text(await AppLocale.fr.build()), contains('Insérez'));
      expect(tutorialSteps('de').first.text(await AppLocale.de.build()), contains('Geben Sie'));
      expect(tutorialSteps('es').first.text(await AppLocale.es.build()), contains('Introduzca'));
      expect(tutorialSteps('pt').first.text(await AppLocale.pt.build()), contains('Entrar'));
    });
  });
}
