import 'dart:async';
import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_starter/core/data/backups/backups_repository.dart';
import 'package:flutter_starter/core/models/backup_model.dart';
import 'package:flutter_starter/core/services/di/locator.dart';
import 'package:flutter_starter/core/services/hive/service.dart';
import 'package:flutter_starter/core/services/i18n/translations.g.dart';
import 'package:flutter_starter/view/screens/backups/backups_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

// Deliberately a single testWidgets covering only the read path (empty
// state -> list -> expand), with delete/repository CRUD covered instead by
// the plain (non-widget) tests in backups_repository_test.dart. Pumping
// BackupsScreen against a real Hive box through more interaction (dialogs,
// multiple writes) than this leaves the isolate's event loop non-idle after
// all assertions pass, hanging flutter_test at process exit even though the
// screen behaves correctly -- a known environment quirk, not a product bug.
void main() {
  late Directory tempDir;
  late BackupsRepository repository;

  setUpAll(() async {
    await dotenv.load();

    tempDir = await Directory.systemTemp.createTemp('backups_test');
    Hive.init(tempDir.path);

    final hiveService = await HiveService.getInstance();
    locator.registerSingleton<HiveService>(hiveService!);

    repository = BackupsRepository();
    locator.registerSingleton<BackupsRepository>(repository);
  });

  tearDownAll(() async {
    locator
      ..unregister<BackupsRepository>()
      ..unregister<HiveService>();
    await Hive.close();
    // Not awaited: deleting the temp dir is real (non-fake-clock) file I/O,
    // which can hang flutter_test's zone when run from tearDownAll (no
    // WidgetTester/runAsync available here to bridge it). Best-effort only
    // -- the OS temp dir gets reclaimed regardless.
    unawaited(tempDir.delete(recursive: true));
  });

  testWidgets('empty state, listing, and expanding backups', (tester) async {
    await tester.pumpWidget(
      TranslationProvider(
        child: const MaterialApp(home: BackupsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // -- Empty state --
    expect(find.text('Aucune sauvegarde trouvée!'), findsOneWidget);

    // Export/import stay available even with nothing saved yet -- a fresh
    // device needs to be able to import before it has any backups of its
    // own. Not tapped here: both trigger real platform channels
    // (file_picker/share_plus) that aren't mocked in this widget test.
    expect(find.text('Exporter les sauvegardes'), findsOneWidget);
    expect(find.text('Importer des sauvegardes'), findsOneWidget);

    // -- Listing: adding to the repository reactively updates the screen,
    // no re-pump of the widget needed. --
    await tester.runAsync(() async {
      await repository.add(
        Backup(
          name: 'Etude 1',
          resolutionHtml: 'Explication détaillée ici',
          xi: '1_2_3',
          ni: '2_4_6',
          date: '01.01.2026 - 10:00',
        ),
      );
      await repository.add(
        Backup(name: 'Etude 2', resolutionHtml: '<b>X = 5</b>', xi: '1_2', ni: '2_4', date: '02.01.2026 - 11:00'),
      );
    });
    await tester.pumpAndSettle();

    expect(find.text('Aucune sauvegarde trouvée!'), findsNothing);
    expect(find.text('Etude 1'), findsOneWidget);
    expect(find.text('Etude 2'), findsOneWidget);
    expect(find.text('01.01.2026 - 10:00'), findsOneWidget);

    // -- Expanding: shows the stored resolution HTML. Plain Text widgets
    // (the ListTile's title/subtitle) also render as RichText internally,
    // so check the resolution content specifically rather than RichText
    // presence. --
    String renderedText() => tester.widgetList<RichText>(find.byType(RichText)).map((w) => w.text.toPlainText()).join('\n');

    expect(renderedText(), isNot(contains('Explication détaillée ici')));

    await tester.tap(find.text('Etude 1'));
    await tester.pumpAndSettle();

    expect(renderedText(), contains('Explication détaillée ici'));
    expect(find.byType(BarChart), findsOneWidget);
  });
}
