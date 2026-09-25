import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter/core/data/backups/backup_data.dart';
import 'package:flutter_starter/core/providers/main/home_provider.dart';
import 'package:flutter_starter/core/routes/router.dart';
import 'package:flutter_starter/core/services/i18n/translations.g.dart';
import 'package:flutter_starter/view/components/backups/load_backup.dart';
import 'package:flutter_starter/view/screens/main_screen.dart';
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

  testWidgets('opens each backup in its calculator, filled in and computed', (tester) async {
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
    // The element of a ConsumerStatefulWidget is a WidgetRef -- standing in
    // for the Backups screen's.
    final ref = tester.element(find.byType(CentralContainer)) as WidgetRef;

    // -- A tab never opened yet: its entry rows come from the load. --
    loadBackupIntoCalculator(
      ref,
      const BackupData(
        kind: BackupKind.continuous,
        columns: [
          [0, 10],
          [10, 20],
          [5, 8.5],
        ],
        selectedStats: ['median'],
        precision: 3,
      ),
    );
    await tester.pumpAndSettle();

    expect(ref.read(homeProvider), HomeTab.continuous);
    expect(fieldTexts(tester), ['0', '10', '5', '10', '20', '8,5']);
    expect(find.text('TABLEAU STATISTIQUE'), findsOneWidget);

    // -- A tab already built: its current rows are replaced. --
    ref.read(homeProvider.notifier).tabIndex = HomeTab.discrete;
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajouter une entrée'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '42');

    loadBackupIntoCalculator(
      ref,
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
    await tester.pumpAndSettle();
    expect(fieldTexts(tester), ['Rouge', '3', 'Bleu', '5']);

    loadBackupIntoCalculator(
      ref,
      const BackupData(
        kind: BackupKind.discrete,
        columns: [
          [1, 2],
          [2, 4],
        ],
        selectedStats: ['mean'],
        precision: 3,
      ),
    );
    await tester.pumpAndSettle();
    expect(ref.read(homeProvider), HomeTab.discrete);
    expect(fieldTexts(tester), ['1', '2', '2', '4']);
    expect(find.text('TABLEAU STATISTIQUE'), findsOneWidget);
  });
}

class _StartOnTutorialTab extends Home {
  @override
  int build() => HomeTab.tutorial;
}
