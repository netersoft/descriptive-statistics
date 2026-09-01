import 'package:flutter_starter/core/data/backups/backups_json.dart';
import 'package:flutter_starter/core/models/backup_model.dart';
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
  });
}
