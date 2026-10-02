import 'package:descriptive_statistics/core/data/backups/backups_json.dart';
import 'package:descriptive_statistics/core/models/backup_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Backup sampleBackup(String name) => Backup(name: name, resolutionHtml: '<b>X = 3</b>', xi: '1_2_3', ni: '2_4_6', date: '01.01.2026 - 10:00');

  group('exportBackupsToJson / parseBackupsJson', () {
    test('round-trips every field for one backup', () {
      final json = exportBackupsToJson([sampleBackup('Etude 1')]);
      final parsed = parseBackupsJson(json);

      expect(parsed, hasLength(1));
      expect(parsed.first.name, 'Etude 1');
      expect(parsed.first.resolutionHtml, '<b>X = 3</b>');
      expect(parsed.first.xi, '1_2_3');
      expect(parsed.first.ni, '2_4_6');
      expect(parsed.first.date, '01.01.2026 - 10:00');
    });

    test('round-trips multiple backups, preserving order', () {
      final json = exportBackupsToJson([sampleBackup('Etude 1'), sampleBackup('Etude 2')]);
      final parsed = parseBackupsJson(json);

      expect(parsed.map((b) => b.name), ['Etude 1', 'Etude 2']);
    });

    test('round-trips an empty list', () {
      expect(parseBackupsJson(exportBackupsToJson([])), isEmpty);
    });

    test('throws on invalid JSON', () {
      expect(() => parseBackupsJson('not json'), throwsFormatException);
    });

    test('throws when the "backups" array is missing', () {
      expect(() => parseBackupsJson('{"app": "Statistique Descriptive"}'), throwsFormatException);
    });

    test('throws when a backup entry is missing a required field', () {
      expect(
        () => parseBackupsJson('{"backups": [{"name": "Etude 1", "xi": "1_2", "ni": "2_4", "date": "01.01.2026"}]}'),
        throwsFormatException,
      );
    });

    test('throws when a backup entry is not an object', () {
      expect(() => parseBackupsJson('{"backups": ["not an object"]}'), throwsFormatException);
    });

    test('round-trips the optional kind, data and save time', () {
      final saved = DateTime(2026, 3, 7, 9, 5);
      final json = exportBackupsToJson([
        Backup(
          name: 'Etude',
          resolutionHtml: '<b>X</b>',
          xi: '1_2',
          ni: '2_4',
          date: '07.03.2026 - 09:05',
          kind: 'discrete',
          data: '{"columns": [[1, 2], [2, 4]], "selectedStats": ["mean"], "precision": 3}',
          createdAt: saved,
        ),
      ]);
      final parsed = parseBackupsJson(json).single;

      expect(parsed.kind, 'discrete');
      expect(parsed.data, contains('"precision": 3'));
      expect(parsed.createdAt, saved);
    });

    test('still reads version 1 files, which have no optional fields', () {
      final parsed = parseBackupsJson(
        '{"version": 1, "backups": [{"name": "Etude", "resolutionHtml": "<b>X</b>", "xi": "1_2", "ni": "2_4", "date": "01.01.2026"}]}',
      ).single;

      expect(parsed.name, 'Etude');
      expect(parsed.kind, isNull);
      expect(parsed.data, isNull);
      expect(parsed.createdAt, isNull);
    });

    test('throws when an optional field has the wrong type', () {
      expect(
        () => parseBackupsJson('{"backups": [{"name": "E", "resolutionHtml": "", "xi": "", "ni": "", "date": "", "kind": 3}]}'),
        throwsFormatException,
      );
    });
  });
}
