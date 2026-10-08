import 'package:descriptive_statistics/core/data/backups/backup_data.dart';
import 'package:descriptive_statistics/core/data/backups/backups_repository.dart';
import 'package:descriptive_statistics/core/models/backup_model.dart';
import 'package:descriptive_statistics/core/providers/settings/settings_provider.dart';
import 'package:descriptive_statistics/core/services/di/locator.dart';
import 'package:descriptive_statistics/core/services/i18n/translations.g.dart';
import 'package:descriptive_statistics/core/tools/constants/chart_options.dart';
import 'package:descriptive_statistics/view/components/calculators/chart_carousel.dart';
import 'package:descriptive_statistics/view/screens/calculators/discrete_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_utils.dart';

void main() {
  late MockSharedPreferencesService mockPrefs;

  setUpAll(() => registerFallbackValue(Backup(name: '', resolutionHtml: '', xi: '', ni: '', date: '')));

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
    testWidgets('fills Xi/Ni rows from a raw series, keeping rows already filled in', (tester) async {
      await pumpScreen(tester);
      await addRow(tester);
      await tester.enterText(find.byType(TextField).first, '10');
      await tester.enterText(find.byType(TextField).at(1), '1');

      await tester.tap(find.text('Série brute'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '3, 5 5;7\n3 2,5');
      await tester.tap(find.text('Compter'));
      await tester.pumpAndSettle();

      final values = [for (final field in tester.widgetList<TextField>(find.byType(TextField))) field.controller!.text];
      expect(values, ['10', '1', '2,5', '1', '3', '2', '5', '2', '7', '1']);
    });

    testWidgets('names the value it cannot read in a raw series', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Série brute'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '1 3,5,5 2');
      await tester.tap(find.text('Compter'));
      await tester.pumpAndSettle();

      expect(find.textContaining('« 3,5,5 »'), findsOneWidget);
      // The dialog stays open so the series can be fixed.
      expect(find.text('Compter'), findsOneWidget);
    });

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
      // mean effectif = Σni/n = 12/3 = 4. Asserting on the rendered HTML
      // explanation (rather than reading provider state directly) exercises
      // the actual HtmlWidget rendering path.
      final explanation = explanationText(tester);
      // French (the default test locale) displays decimals with a comma.
      expect(explanation, contains('X = 2,333'));
      expect(explanation, contains('Effectif moyen'));
      expect(explanation, contains('\u0304 = 4'));
      expect(explanation, contains('MOYENNES'));
      expect(explanation, contains('ÉTENDUE'));
      // Save and Share sit side by side once a result exists.
      expect(find.text('Enregistrer'), findsOneWidget);
      expect(find.text('Partager'), findsOneWidget);
    });

    testWidgets('accepts comma as the decimal separator, as fr/de/es/pt keyboards produce', (tester) async {
      await pumpScreen(tester);

      await addRow(tester);
      await addRow(tester);

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), '1,5');
      await tester.enterText(textFields.at(1), '2');
      await tester.enterText(textFields.at(2), '2,5');
      await tester.enterText(textFields.at(3), '4');

      await tester.tap(find.text('Calculer'));
      await tester.pumpAndSettle();

      expect(find.text('Erreur de syntaxe!'), findsNothing);
      expect(find.text('TABLEAU STATISTIQUE'), findsOneWidget);
    });

    testWidgets('flags a non-unique mode in the explanation instead of silently picking one', (tester) async {
      await pumpScreen(tester);

      for (var i = 0; i < 3; i++) {
        await addRow(tester);
      }

      final textFields = find.byType(TextField);
      const rows = [
        ['1', '5'],
        ['2', '2'],
        ['3', '5'],
      ];
      for (var i = 0; i < rows.length; i++) {
        await tester.enterText(textFields.at(i * 2), rows[i][0]);
        await tester.enterText(textFields.at(i * 2 + 1), rows[i][1]);
      }

      await tester.tap(find.text('Calculer'));
      await tester.pumpAndSettle();

      final explanation = explanationText(tester);
      expect(explanation, contains('Mo = 1, 3'));
      expect(explanation, contains('plurimodale'));
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

    testWidgets('bulk-imports pasted rows, replacing empty leftover rows, and calculates from them', (tester) async {
      await pumpScreen(tester);

      // A leftover empty row from before the paste should be cleared away.
      await addRow(tester);

      await tester.tap(find.text('Importer des données'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, '1;2\n2,5;4\n3;6');
      await tester.tap(find.text('Importer'));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(6));
      expect(find.widgetWithText(TextField, '1'), findsOneWidget);
      expect(find.widgetWithText(TextField, '2,5'), findsOneWidget);

      await tester.tap(find.text('Calculer'));
      await tester.pumpAndSettle();

      expect(find.text('Erreur de syntaxe!'), findsNothing);
      expect(find.text('TABLEAU STATISTIQUE'), findsOneWidget);
    });

    testWidgets('rejects a pasted row with the wrong number of fields', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Importer des données'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, '1;2;3');
      await tester.tap(find.text('Importer'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Format invalide'), findsOneWidget);
      // The dialog stays open on error instead of importing anything.
      expect(find.byType(AlertDialog), findsOneWidget);
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

    testWidgets('updates the charts as soon as the chart types change in Settings, without recalculating', (tester) async {
      when(() => mockPrefs.setStringList(any(), any())).thenAnswer((_) async => true);
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
      expect(find.byType(BarChart), findsOneWidget);

      // What the Settings screen does when the user keeps only "Lignes".
      ProviderScope.containerOf(
        tester.element(find.byType(DiscreteScreen)),
      ).read(settingsProvider.notifier).setDiscreteChartTypes({QuantitativeChartType.line});
      await tester.pumpAndSettle();

      expect(find.byType(BarChart), findsNothing);
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('keeps the explanation at the precision it was calculated with after the setting changes', (tester) async {
      await pumpScreen(tester);

      await addRow(tester);
      await addRow(tester);
      await addRow(tester);
      final textFields = find.byType(TextField);
      // xi=[1,2,4]: the Xi standard deviation shown in the correlation step
      // is √(42/18) = 1.52753 -> "1,528" at 3 decimals, "1,5" at 1.
      const rows = [
        ['1', '1'],
        ['2', '2'],
        ['4', '7'],
      ];
      for (var i = 0; i < rows.length; i++) {
        await tester.enterText(textFields.at(i * 2), rows[i][0]);
        await tester.enterText(textFields.at(i * 2 + 1), rows[i][1]);
      }
      await tester.tap(find.text('Calculer'));
      await tester.pumpAndSettle();
      expect(explanationText(tester), contains('1,528'));

      // The user lowers the precision in Settings, then comes back and
      // interacts with the screen (anything that rebuilds it) without
      // recalculating.
      when(() => mockPrefs.getInt(any(), defaultValue: any(named: 'defaultValue'))).thenReturn(1);
      await tester.tap(find.text('Calculs'));
      await tester.pumpAndSettle();

      final explanation = explanationText(tester);
      expect(explanation, contains('1,528'));
      expect(explanation, isNot(contains('( 1,5 *')));
    });

    testWidgets('saves the calculation with its kind, data and save time so the backup can be recomputed', (tester) async {
      final repository = _MockBackupsRepository();
      when(() => repository.add(any())).thenAnswer((_) async {});
      when(() => repository.keys).thenReturn(const [0]);
      locator.registerSingleton<BackupsRepository>(repository);
      addTearDown(() => locator.unregister<BackupsRepository>());

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

      await tester.ensureVisible(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Etude');
      await tester.tap(find.widgetWithText(TextButton, 'Enregistrer'));
      await tester.pumpAndSettle();

      final saved = verify(() => repository.add(captureAny())).captured.single as Backup;
      expect(saved.name, 'Etude');
      expect(saved.kind, 'discrete');
      expect(saved.createdAt, isNotNull);
      final data = BackupData.decode(saved.kind, saved.data)!;
      expect(data.numbers(0), [1, 2]);
      expect(data.numbers(1), [2, 4]);
      expect(data.selectedStats, containsAll(['mean', 'median', 'charts']));
      expect(data.precision, 3);
    });
  });
}

class _MockBackupsRepository extends Mock implements BackupsRepository {}
