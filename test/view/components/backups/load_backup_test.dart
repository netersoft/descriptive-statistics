import 'dart:async';

import 'package:descriptive_statistics/core/data/backups/backup_data.dart';
import 'package:descriptive_statistics/core/providers/calculators/discrete_provider.dart';
import 'package:descriptive_statistics/core/providers/main/home_provider.dart';
import 'package:descriptive_statistics/core/routes/router.dart';
import 'package:descriptive_statistics/core/services/i18n/translations.g.dart';
import 'package:descriptive_statistics/view/components/backups/load_backup.dart';
import 'package:descriptive_statistics/view/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_utils.dart';

void main() {
  setUp(() async {
    final mockPrefs = MockSharedPreferencesService();
    when(() => mockPrefs.getInt(any(), defaultValue: any(named: 'defaultValue'))).thenReturn(3);
    await setupTestLocator(sharedPreferencesService: mockPrefs);
  });

  tearDown(teardownTestLocator);

  List<String> fieldTexts(WidgetTester tester) => [
    for (final field in tester.widgetList<TextField>(find.byType(TextField))) field.controller!.text,
  ];

  testWidgets('opens each backup in its calculator, asking before replacing typed data', (tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = createRouter(initialLocation: '/main', observers: []);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [homeProvider.overrideWith(_StartOnTutorialTab.new)],
        child: TranslationProvider(child: MaterialApp.router(routerConfig: router)),
      ),
    );
    await tester.pumpAndSettle();
    // The element of a ConsumerStatefulWidget is both a BuildContext and a
    // WidgetRef -- standing in for the Backups screen's.
    final element = tester.element(find.byType(CentralContainer));
    final ref = element as WidgetRef;

    Future<void> load(BackupData data) async {
      unawaited(loadBackupIntoCalculator(element, ref, data));
      await tester.pumpAndSettle();
    }

    const continuous = BackupData(
      kind: BackupKind.continuous,
      columns: [
        [0, 10],
        [10, 20],
        [5, 8.5],
      ],
      selectedStats: ['median'],
      precision: 3,
    );
    const discrete = BackupData(
      kind: BackupKind.discrete,
      columns: [
        [1, 2],
        [2, 4],
      ],
      selectedStats: ['mean'],
      precision: 3,
    );

    // -- A tab never opened yet: its entry rows come from the load, no
    // confirmation needed. --
    await load(continuous);

    expect(find.byType(AlertDialog), findsNothing);
    expect(ref.read(homeProvider), HomeTab.continuous);
    expect(fieldTexts(tester), ['0', '10', '5', '10', '20', '8,5']);
    expect(find.text('TABLEAU STATISTIQUE'), findsOneWidget);

    // -- Loading over rows that hold data (here the previous load) asks
    // first. --
    await load(continuous);
    expect(find.text('Remplacer la saisie ?'), findsOneWidget);
    await tester.tap(find.text('Remplacer'));
    await tester.pumpAndSettle();
    expect(fieldTexts(tester), ['0', '10', '5', '10', '20', '8,5']);

    // -- A tab already built, with a row the user typed in. --
    ref.read(homeProvider.notifier).tabIndex = HomeTab.discrete;
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajouter une entrée'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '42');

    // Canceling leaves the typed row alone.
    ref.read(homeProvider.notifier).tabIndex = HomeTab.tutorial;
    await tester.pumpAndSettle();
    await load(discrete);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(ref.read(homeProvider), HomeTab.tutorial);
    expect(ref.read(discreteCalculatorProvider).result, isNull);

    ref.read(homeProvider.notifier).tabIndex = HomeTab.discrete;
    await tester.pumpAndSettle();
    expect(fieldTexts(tester), ['42', '']);

    // Confirming replaces it.
    await load(discrete);
    await tester.tap(find.text('Remplacer'));
    await tester.pumpAndSettle();
    expect(ref.read(homeProvider), HomeTab.discrete);
    expect(fieldTexts(tester), ['1', '2', '2', '4']);
    expect(find.text('TABLEAU STATISTIQUE'), findsOneWidget);

    // -- Rows that only hold blanks don't count as data. --
    ref.read(homeProvider.notifier).tabIndex = HomeTab.qualitative;
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajouter une entrée'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '  ');

    await load(
      const BackupData(
        kind: BackupKind.qualitative,
        columns: [
          ['Rouge', 'Bleu'],
          [3, 5],
        ],
        selectedStats: ['mode'],
        precision: 3,
      ),
    );
    expect(find.byType(AlertDialog), findsNothing);
    expect(fieldTexts(tester), ['Rouge', '3', 'Bleu', '5']);
  });
}

class _StartOnTutorialTab extends Home {
  @override
  int build() => HomeTab.tutorial;
}
