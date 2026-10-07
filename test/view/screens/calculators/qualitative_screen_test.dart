import 'package:descriptive_statistics/core/services/i18n/translations.g.dart';
import 'package:descriptive_statistics/view/screens/calculators/qualitative_screen.dart';
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
    tester.view.physicalSize = const Size(800, 3600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: TranslationProvider(
          child: const MaterialApp(home: QualitativeScreen()),
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

  group('QualitativeScreen', () {
    testWidgets('fills modality/effectif rows from a raw series', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Série brute'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Rouge; Bleu\nRouge, Très bien');
      await tester.tap(find.text('Compter'));
      await tester.pumpAndSettle();

      final values = [for (final field in tester.widgetList<TextField>(find.byType(TextField))) field.controller!.text];
      expect(values, ['Rouge', '2', 'Bleu', '1', 'Très bien', '1']);
    });

    testWidgets('adding rows, calculating, and rendering the table and explanation', (tester) async {
      await pumpScreen(tester);

      for (var i = 0; i < 6; i++) {
        await addRow(tester);
      }

      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(12));

      // Modalities A, B, A, C, B, A with values 10, 20, 15, 5, 10, 25:
      // A = 10+15+25 = 50, B = 20+10 = 30, C = 5, total = 85, mode = A --
      // same hand-computed dataset as qualitative_stats_test.dart.
      const rows = [
        ['A', '10'],
        ['B', '20'],
        ['A', '15'],
        ['C', '5'],
        ['B', '10'],
        ['A', '25'],
      ];
      for (var i = 0; i < rows.length; i++) {
        await tester.enterText(textFields.at(i * 2), rows[i][0]);
        await tester.enterText(textFields.at(i * 2 + 1), rows[i][1]);
      }

      await tester.tap(find.text('Calculer'));
      await tester.pumpAndSettle();

      expect(find.text('TABLEAU STATISTIQUE'), findsOneWidget);
      expect(find.text('A'), findsWidgets);
      // "50" (A's effectif) appears twice in the table: its own effectif
      // cell and its cumulative-effectif cell (A is the first row, so both
      // are equal).
      expect(find.text('50'), findsWidgets);

      final explanation = explanationText(tester);
      expect(explanation, contains('E = 85'));
      // French (the default test locale) displays decimals with a comma.
      expect(explanation, contains('\u0304 = 28,3333'));
      expect(explanation, contains('Mo >>> A'));
      expect(explanation, contains('EFFECTIF TOTAL'));
    });

    testWidgets('shows an error snackbar with fewer than two rows', (tester) async {
      await pumpScreen(tester);

      await addRow(tester);
      await tester.tap(find.text('Calculer'));
      await tester.pump();

      expect(find.text('Données Insuffisantes!'), findsOneWidget);
    });

    testWidgets('shows an error snackbar for a non-numeric effectif', (tester) async {
      await pumpScreen(tester);

      await addRow(tester);
      await addRow(tester);
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'A');
      await tester.enterText(textFields.at(1), 'not-a-number');
      await tester.enterText(textFields.at(2), 'B');
      await tester.enterText(textFields.at(3), '10');

      await tester.tap(find.text('Calculer'));
      await tester.pump();

      expect(find.text('Erreur de syntaxe!'), findsOneWidget);
    });

    testWidgets('removing an entry row removes its fields', (tester) async {
      await pumpScreen(tester);

      await addRow(tester);
      expect(find.byType(TextField), findsNWidgets(2));

      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('shows a bar chart and pie chart by default', (tester) async {
      await pumpScreen(tester);

      await addRow(tester);
      await addRow(tester);
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'A');
      await tester.enterText(textFields.at(1), '10');
      await tester.enterText(textFields.at(2), 'B');
      await tester.enterText(textFields.at(3), '20');

      await tester.tap(find.text('Calculer'));
      await tester.pumpAndSettle();

      expect(find.byType(BarChart), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_right).first);
      await tester.pumpAndSettle();

      expect(find.byType(PieChart), findsOneWidget);
    });

    testWidgets('bulk-imports pasted modality/effectif rows and calculates from them', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Importer des données'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, 'A;10\nB;20\nA;15\nC;5');
      await tester.tap(find.text('Importer'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNWidgets(8));
      expect(find.widgetWithText(TextField, 'A'), findsNWidgets(2));

      await tester.tap(find.text('Calculer'));
      await tester.pumpAndSettle();

      expect(find.text('Erreur de syntaxe!'), findsNothing);
      expect(find.text('TABLEAU STATISTIQUE'), findsOneWidget);
    });
  });
}
