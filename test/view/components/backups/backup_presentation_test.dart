import 'package:flutter_starter/core/data/backups/backup_data.dart';
import 'package:flutter_starter/core/models/backup_model.dart';
import 'package:flutter_starter/core/services/i18n/translations.g.dart';
import 'package:flutter_starter/view/components/backups/backup_presentation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  tearDown(() => LocaleSettings.setLocaleRaw('fr'));

  Backup backup({BackupData? data, DateTime? createdAt, String xi = '1.0_2.0_4.5', String ni = '2.0_4.0_7.0'}) => Backup(
    name: 'Etude',
    resolutionHtml: 'HTML saved at the time',
    xi: xi,
    ni: ni,
    date: '07.03.2026 - 09:05',
    kind: data?.kind.name,
    data: data?.encode(),
    createdAt: createdAt,
  );

  const discrete = BackupData(
    kind: BackupKind.discrete,
    columns: [
      [1, 2, 4.5],
      [2, 4, 7],
    ],
    selectedStats: ['mean'],
    precision: 3,
  );

  group('backupExplanationHtml', () {
    test('rebuilds the explanation in the current language from the stored data', () async {
      await LocaleSettings.setLocaleRaw('en');
      final english = backupExplanationHtml(backup(data: discrete));
      await LocaleSettings.setLocaleRaw('fr');
      final french = backupExplanationHtml(backup(data: discrete));

      expect(english, contains('MEANS'));
      expect(french, contains('MOYENNES'));
      // Same numbers either way: X = 41.5 / 13 = 3.192.
      expect(english, contains('X = 3.192'));
      expect(french, contains('X = 3,192'));
      // Only the selected stats are shown.
      expect(french, isNot(contains('MODE')));
    });

    test('rebuilds continuous and qualitative backups too', () {
      const continuous = BackupData(
        kind: BackupKind.continuous,
        columns: [
          [0, 10],
          [10, 20],
          [5, 8],
        ],
        selectedStats: ['median'],
        precision: 3,
      );
      const qualitative = BackupData(
        kind: BackupKind.qualitative,
        columns: [
          ['Rouge', 'Bleu'],
          [3, 5],
        ],
        selectedStats: ['mode'],
        precision: 3,
      );

      expect(backupExplanationHtml(backup(data: continuous)), contains('Me = '));
      expect(backupExplanationHtml(backup(data: qualitative)), contains('Bleu'));
    });

    test('falls back to the stored HTML for backups without data', () {
      expect(backupExplanationHtml(backup()), 'HTML saved at the time');
    });

    test('falls back to the stored HTML when the data no longer computes', () {
      const tooShort = BackupData(
        kind: BackupKind.discrete,
        columns: [
          [1],
          [2],
        ],
        selectedStats: ['mean'],
        precision: 3,
      );

      expect(backupExplanationHtml(backup(data: tooShort)), 'HTML saved at the time');
    });
  });

  group('backupChartData', () {
    test('labels numeric backups like the calculators do', () {
      final (frLabels, values) = backupChartData(backup(), 'fr')!;
      final (enLabels, _) = backupChartData(backup(), 'en')!;

      expect(frLabels, ['1', '2', '4,5']);
      expect(enLabels, ['1', '2', '4.5']);
      expect(values, [2.0, 4.0, 7.0]);
    });

    test('labels qualitative backups with their modalities, not their indices', () {
      const qualitative = BackupData(
        kind: BackupKind.qualitative,
        columns: [
          ['Rouge', 'Bleu'],
          [3, 5],
        ],
        selectedStats: ['mode'],
        precision: 3,
      );

      final (labels, values) = backupChartData(backup(data: qualitative, xi: '0_1', ni: '3.0_5.0'), 'fr')!;

      expect(labels, ['Rouge', 'Bleu']);
      expect(values, [3.0, 5.0]);
    });

    test('is null when the stored values do not line up', () {
      expect(backupChartData(backup(ni: '2.0_4.0'), 'fr'), isNull);
    });
  });

  group('backupDateLabel', () {
    test('uses the stored date string for backups without a save time', () {
      expect(backupDateLabel(backup(), 'en'), '07.03.2026 - 09:05');
    });

    test('formats the save time in the given language', () async {
      await initializeDateFormatting('fr');
      final saved = backup(createdAt: DateTime(2026, 3, 7, 9, 5));

      expect(backupDateLabel(saved, 'en'), '3/7/2026 09:05');
      expect(backupDateLabel(saved, 'fr'), '07/03/2026 09:05');
    });
  });
}
