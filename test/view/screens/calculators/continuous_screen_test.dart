import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter/core/services/i18n/translations.g.dart';
import 'package:flutter_starter/view/screens/calculators/continuous_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_utils.dart';

void main() {
  late MockSharedPreferencesService mockPrefs;

  setUp(() async {
    mockPrefs = MockSharedPreferencesService();
    when(() => mockPrefs.getInt(any(), defaultValue: any(named: 'defaultValue'))).thenReturn(4);
    await setupTestLocator(sharedPreferencesService: mockPrefs);
  });

  tearDown(teardownTestLocator);

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: TranslationProvider(
          child: const MaterialApp(home: ContinuousScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> addRow(WidgetTester tester) async {
    await tester.tap(find.text('Ajouter une entrée'));
    await tester.pumpAndSettle();
  }

  // flutter_widget_from_html_core renders its whole output into a single
  // RichText, so find.textContaining (which only does substring matching on
  // plain Text widgets) can't see inside it -- read its plain text directly.
  String explanationText(WidgetTester tester) => tester.widgetList<RichText>(find.byType(RichText)).map((w) => w.text.toPlainText()).join('\n');

  group('ContinuousScreen', () {
    testWidgets('adding rows, calculating, and rendering the table and explanation', (tester) async {
      await pumpScreen(tester);

      for (var i = 0; i < 4; i++) {
        await addRow(tester);
      }

      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(12));

      // Classes [0,10), [10,20), [20,30), [30,40) with ni = 5, 8, 4, 3 --
      // same hand-computed dataset as continuous_stats_test.dart:
      // weighted mean 17.5, mode ~14.2857, median 16.25.
      const rows = [
        ['0', '10', '5'],
        ['10', '20', '8'],
        ['20', '30', '4'],
        ['30', '40', '3'],
      ];
      for (var i = 0; i < rows.length; i++) {
        await tester.enterText(textFields.at(i * 3), rows[i][0]);
        await tester.enterText(textFields.at(i * 3 + 1), rows[i][1]);
        await tester.enterText(textFields.at(i * 3 + 2), rows[i][2]);
      }

      await tester.tap(find.text('Calculer'));
      await tester.pumpAndSettle();

      expect(find.text('TABLEAU STATISTIQUE'), findsOneWidget);

      final explanation = explanationText(tester);
      expect(explanation, contains('X = 17.5'));
      expect(explanation, contains('Mo = 14.2857'));
      expect(explanation, contains('Me = 16.25'));
      expect(explanation, contains('Classe Modale'));
      expect(explanation, contains('Classe Mediante'));
      expect(explanation, contains('MOYENNES'));
      expect(explanation, contains('ETENDUE'));
    });

    testWidgets('shows an error snackbar with fewer than two rows', (tester) async {
      await pumpScreen(tester);

      await addRow(tester);
      await tester.tap(find.text('Calculer'));
      await tester.pump();

      expect(find.text('Données Insuffisantes!'), findsOneWidget);
    });

    testWidgets('shows an error snackbar for a negative class width', (tester) async {
      await pumpScreen(tester);

      await addRow(tester);
      await addRow(tester);
      final textFields = find.byType(TextField);
      // First row has L2 < L1, a negative class width.
      await tester.enterText(textFields.at(0), '20');
      await tester.enterText(textFields.at(1), '10');
      await tester.enterText(textFields.at(2), '5');
      await tester.enterText(textFields.at(3), '20');
      await tester.enterText(textFields.at(4), '30');
      await tester.enterText(textFields.at(5), '5');

      await tester.tap(find.text('Calculer'));
      await tester.pump();

      expect(
        find.text('Valeurs invalides : les effectifs doivent être positifs, et leur somme ne peut pas être nulle !'),
        findsOneWidget,
      );
    });

    testWidgets('removing an entry row removes its fields', (tester) async {
      await pumpScreen(tester);

      await addRow(tester);
      expect(find.byType(TextField), findsNWidgets(3));

      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
    });
  });
}
