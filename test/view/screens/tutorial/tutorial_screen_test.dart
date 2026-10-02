import 'package:descriptive_statistics/core/services/i18n/translations.g.dart';
import 'package:descriptive_statistics/view/screens/tutorial/tutorial_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TutorialScreen renders the how-to-proceed steps', (tester) async {
    await tester.pumpWidget(
      TranslationProvider(
        child: const MaterialApp(home: TutorialScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Comment procéder ?'), findsOneWidget);
    expect(
      find.text("1. Insérez les données de l'étude ligne par ligne (la virgule est acceptée comme séparateur décimal), ou collez-en plusieurs à la fois"),
      findsOneWidget,
    );
    expect(find.text('2. Sélectionnez les critères statistiques à étudier'), findsOneWidget);
    expect(find.text("3. Cliquez sur le bouton 'Calculer'"), findsOneWidget);
    expect(
      find.text('4. Sauvegardez votre étude pour y accéder ultérieurement, ou exportez vos sauvegardes pour les emporter sur un autre appareil'),
      findsOneWidget,
    );
    expect(find.byType(Image), findsNWidgets(4));
  });
}
