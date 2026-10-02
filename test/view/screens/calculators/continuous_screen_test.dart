import 'package:descriptive_statistics/core/services/i18n/translations.g.dart';
import 'package:descriptive_statistics/view/screens/calculators/continuous_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      // French (the default test locale) displays decimals with a comma.
      expect(explanation, contains('X = 17,5'));
      expect(explanation, contains('Mo = 14,2857'));
      expect(explanation, contains('Me = 16,25'));
      expect(explanation, contains('Classe Modale'));
      expect(explanation, contains('Classe Mediante'));
      expect(explanation, contains('MOYENNES'));
      expect(explanation, contains('ETENDUE'));
    });

    testWidgets('shows the correct modal/median class bounds when classes are entered out of order', (tester) async {
      await pumpScreen(tester);

      for (var i = 0; i < 4; i++) {
        await addRow(tester);
      }

      // Same classes/effectifs as the main fixture above (modal/median
      // class [10,20), ni=8), entered out of order. The explanation panel
      // is handed the same (sorted) l1/l2 arrays the engine computed
      // modalClassIndex/medianClassIndex against -- if it were handed the
      // raw entry-order arrays instead, it would label the wrong class
      // interval here even though the highlighted Mo/Me values stayed
      // correct.
      const rows = [
        ['20', '30', '4'],
        ['0', '10', '5'],
        ['30', '40', '3'],
        ['10', '20', '8'],
      ];
      final textFields = find.byType(TextField);
      for (var i = 0; i < rows.length; i++) {
        await tester.enterText(textFields.at(i * 3), rows[i][0]);
        await tester.enterText(textFields.at(i * 3 + 1), rows[i][1]);
        await tester.enterText(textFields.at(i * 3 + 2), rows[i][2]);
      }

      await tester.tap(find.text('Calculer'));
      await tester.pumpAndSettle();

      final explanation = explanationText(tester);
      expect(explanation, contains('10 - 20'));
      expect(explanation, isNot(contains('0 - 10')));
      expect(explanation, isNot(contains('20 - 30')));
      expect(explanation, isNot(contains('30 - 40')));
    });

    testWidgets('shows an error snackbar with fewer than two rows', (tester) async {
      await pumpScreen(tester);

      await addRow(tester);
      await tester.tap(find.text('Calculer'));
      await tester.pump();

      expect(find.text('Données Insuffisantes!'), findsOneWidget);
    });

    testWidgets('explains the class bounds when a class has a negative width', (tester) async {
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
        find.text('Classe invalide : la borne supérieure (L2) doit être strictement supérieure à la borne inférieure (L1) !'),
        findsOneWidget,
      );
    });

    testWidgets('shows a dedicated error snackbar for overlapping classes', (tester) async {
      await pumpScreen(tester);

      await addRow(tester);
      await addRow(tester);
      final textFields = find.byType(TextField);
      // [0, 20[ then [10, 30[: values between 10 and 20 would be counted twice.
      await tester.enterText(textFields.at(0), '0');
      await tester.enterText(textFields.at(1), '20');
      await tester.enterText(textFields.at(2), '5');
      await tester.enterText(textFields.at(3), '10');
      await tester.enterText(textFields.at(4), '30');
      await tester.enterText(textFields.at(5), '5');

      await tester.tap(find.text('Calculer'));
      await tester.pump();

      expect(find.text('Les classes se chevauchent : chaque classe doit commencer après la fin de la précédente.'), findsOneWidget);
    });

    testWidgets('removing an entry row removes its fields', (tester) async {
      await pumpScreen(tester);

      await addRow(tester);
      expect(find.byType(TextField), findsNWidgets(3));

      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('bulk-imports pasted 3-field rows and calculates from them', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Importer des données'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, '0;10;5\n10;20;8\n20;30;4\n30;40;3');
      await tester.tap(find.text('Importer'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNWidgets(12));

      await tester.tap(find.text('Calculer'));
      await tester.pumpAndSettle();

      expect(find.text('Erreur de syntaxe!'), findsNothing);
      expect(find.text('TABLEAU STATISTIQUE'), findsOneWidget);
    });

    Future<List<double>> barHeightsFor(WidgetTester tester, List<List<String>> rows) async {
      await pumpScreen(tester);
      for (var i = 0; i < rows.length; i++) {
        await addRow(tester);
      }
      final textFields = find.byType(TextField);
      for (var i = 0; i < rows.length; i++) {
        for (var field = 0; field < 3; field++) {
          await tester.enterText(textFields.at(i * 3 + field), rows[i][field]);
        }
      }
      await tester.tap(find.text('Calculer'));
      await tester.pumpAndSettle();

      return [for (final group in tester.widget<BarChart>(find.byType(BarChart)).data.barGroups) group.barRods.single.toY];
    }

    group('raw series', () {
      List<String> fieldTexts(WidgetTester tester) => [
        for (final field in tester.widgetList<TextField>(find.byType(TextField))) field.controller!.text,
      ];

      Finder dialogField(int index) => find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField)).at(index);
      // In the dialog: the class start and width, then the series.
      final startField = dialogField(0);
      final widthField = dialogField(1);
      final seriesField = dialogField(2);

      testWidgets('groups the values into classes, replacing the rows, and reopens with the last input', (tester) async {
        await pumpScreen(tester);
        await addRow(tester);
        await tester.enterText(find.byType(TextField).first, '99');

        await tester.tap(find.text('Série brute'));
        await tester.pumpAndSettle();
        await tester.enterText(seriesField, '0 5 9,9 10 12 20');
        await tester.enterText(startField, '0');
        await tester.enterText(widthField, '10');
        await tester.tap(find.text('Compter'));
        await tester.pumpAndSettle();

        expect(fieldTexts(tester), ['0', '10', '3', '10', '20', '2', '20', '30', '1']);

        await tester.tap(find.text('Série brute'));
        await tester.pumpAndSettle();
        expect(tester.widget<TextField>(seriesField).controller!.text, '0 5 9,9 10 12 20');
        expect(tester.widget<TextField>(widthField).controller!.text, '10');

        await tester.enterText(widthField, '12,5');
        await tester.tap(find.text('Compter'));
        await tester.pumpAndSettle();
        expect(fieldTexts(tester), ['0', '12,5', '5', '12,5', '25', '1']);
      });

      testWidgets('chooses the classes when the start and width are left blank', (tester) async {
        await pumpScreen(tester);

        await tester.tap(find.text('Série brute'));
        await tester.pumpAndSettle();
        expect(find.text('Auto'), findsNWidgets(2));
        await tester.enterText(seriesField, '3 7 12 15 18 22 25 29 33 38 41 47');
        await tester.tap(find.text('Compter'));
        await tester.pumpAndSettle();

        expect(fieldTexts(tester), ['0', '10', '2', '10', '20', '3', '20', '30', '3', '30', '40', '2', '40', '50', '2']);
      });

      testWidgets('explains a start above the smallest value', (tester) async {
        await pumpScreen(tester);

        await tester.tap(find.text('Série brute'));
        await tester.pumpAndSettle();
        await tester.enterText(seriesField, '5 2,5 8');
        await tester.enterText(startField, '3');
        await tester.tap(find.text('Compter'));
        await tester.pumpAndSettle();

        expect(find.textContaining('plus petite valeur (2,5)'), findsOneWidget);
        expect(find.text('Compter'), findsOneWidget);
      });
    });

    testWidgets('plots densities, and says so, when class widths differ', (tester) async {
      // [0,10) is 10 wide with ni 10, [10,30) is 20 wide with ni 16:
      // densities 1 and 0.8.
      final heights = await barHeightsFor(tester, [
        ['0', '10', '10'],
        ['10', '30', '16'],
      ]);

      expect(heights, [1, 0.8]);
      expect(find.textContaining('les graphiques représentent les densités'), findsOneWidget);
    });

    testWidgets('keeps plotting effectifs when every class has the same width', (tester) async {
      final heights = await barHeightsFor(tester, [
        ['0', '10', '10'],
        ['10', '20', '16'],
      ]);

      expect(heights, [10, 16]);
      expect(find.textContaining('les graphiques représentent les densités'), findsNothing);
    });
  });
}
