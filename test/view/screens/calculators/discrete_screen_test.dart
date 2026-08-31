import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter/core/services/i18n/translations.g.dart';
import 'package:flutter_starter/view/components/calculators/chart_carousel.dart';
import 'package:flutter_starter/view/screens/calculators/discrete_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_utils.dart';

void main() {
  late MockSharedPreferencesService mockPrefs;

  setUp(() async {
    mockPrefs = MockSharedPreferencesService();
    when(() => mockPrefs.getInt(any(), defaultValue: any(named: 'defaultValue'))).thenReturn(3);
    await setupTestLocator(sharedPreferencesService: mockPrefs);
  });

  tearDown(teardownTestLocator);

  Future<void> pumpScreen(WidgetTester tester) async {
    // Tall enough that the screen's content never needs off-screen taps to
    // be scrolled into view first.
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: TranslationProvider(
          child: const MaterialApp(home: DiscreteScreen()),
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

  group('DiscreteScreen', () {
    testWidgets('adding rows, calculating, and rendering the table and explanation', (tester) async {
      await pumpScreen(tester);

      for (var i = 0; i < 3; i++) {
        await addRow(tester);
      }

      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(6));

      const rows = [
        ['1', '2'],
        ['2', '4'],
        ['3', '6'],
      ];
      for (var i = 0; i < rows.length; i++) {
        await tester.enterText(textFields.at(i * 2), rows[i][0]);
        await tester.enterText(textFields.at(i * 2 + 1), rows[i][1]);
      }

      await tester.tap(find.text('Calculer'));
      await tester.pumpAndSettle();

      expect(find.text('TABLEAU STATISTIQUE'), findsOneWidget);
      // xi=[1,2,3], ni=[2,4,6]: weighted mean = Σxini/Σni = 28/12 = 2.333,
      // simple mean = Σni/n = 12/3 = 4. Asserting on the rendered HTML
      // explanation (rather than reading provider state directly) exercises
      // the actual HtmlWidget rendering path.
      final explanation = explanationText(tester);
      expect(explanation, contains('X = 2.333'));
      expect(explanation, contains('X = 4'));
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

    testWidgets('shows an error snackbar for a non-numeric entry', (tester) async {
      await pumpScreen(tester);

      await addRow(tester);
      await addRow(tester);
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'abc');
      await tester.enterText(textFields.at(1), '2');
      await tester.enterText(textFields.at(2), '2');
      await tester.enterText(textFields.at(3), '4');

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

    testWidgets('unchecking a stat option hides its section from the explanation', (tester) async {
      await pumpScreen(tester);

      await addRow(tester);
      await addRow(tester);
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), '1');
      await tester.enterText(textFields.at(1), '2');
      await tester.enterText(textFields.at(2), '2');
      await tester.enterText(textFields.at(3), '4');

      // Expand the checklist and uncheck "Mode".
      await tester.tap(find.text('Calculs'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Mode'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Calculer'));
      await tester.pumpAndSettle();

      final explanation = explanationText(tester);
      expect(explanation, isNot(contains('MODE')));
      expect(explanation, contains('MOYENNES'));
    });

    testWidgets('shows a chart carousel by default and hides it when unchecked', (tester) async {
      await pumpScreen(tester);

      await addRow(tester);
      await addRow(tester);
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), '1');
      await tester.enterText(textFields.at(1), '2');
      await tester.enterText(textFields.at(2), '2');
      await tester.enterText(textFields.at(3), '4');

      await tester.tap(find.text('Calculer'));
      await tester.pumpAndSettle();

      // "Représentation graphique" is checked by default (select-all), so
      // the carousel renders with both fallback chart types (no chart-type
      // preference stubbed on mockPrefs). PageView only builds the current
      // page, so the bar chart is the only one in the tree until paging.
      expect(find.byType(ChartCarousel), findsOneWidget);
      expect(find.byType(BarChart), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_right).first);
      await tester.pumpAndSettle();

      expect(find.byType(LineChart), findsOneWidget);

      await tester.tap(find.text('Calculs'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Représentation graphique'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Calculer'));
      await tester.pumpAndSettle();

      expect(find.byType(ChartCarousel), findsNothing);
    });
  });
}
