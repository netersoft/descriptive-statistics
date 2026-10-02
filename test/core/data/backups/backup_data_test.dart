import 'package:descriptive_statistics/core/data/backups/backup_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BackupData', () {
    test('round-trips through encode/decode', () {
      const data = BackupData(
        kind: BackupKind.continuous,
        columns: [
          [0, 10],
          [10, 20],
          [5, 8],
        ],
        selectedStats: ['mean', 'median'],
        precision: 4,
      );

      final decoded = BackupData.decode('continuous', data.encode())!;

      expect(decoded.kind, BackupKind.continuous);
      expect(decoded.numbers(0), [0, 10]);
      expect(decoded.numbers(2), [5, 8]);
      expect(decoded.selectedStats, ['mean', 'median']);
      expect(decoded.precision, 4);
    });

    test('keeps qualitative modalities as strings', () {
      const data = BackupData(
        kind: BackupKind.qualitative,
        columns: [
          ['Rouge', 'Bleu'],
          [3, 5],
        ],
        selectedStats: ['mode'],
        precision: 3,
      );

      final decoded = BackupData.decode('qualitative', data.encode())!;

      expect(decoded.strings(0), ['Rouge', 'Bleu']);
      expect(decoded.numbers(1), [3, 5]);
    });

    test('is null for backups saved before the data was stored', () {
      expect(BackupData.decode(null, null), isNull);
      expect(BackupData.decode('discrete', null), isNull);
    });

    test('is null for data it cannot use', () {
      const valid = '{"columns": [[1, 2], [3, 4]], "selectedStats": ["mean"], "precision": 3}';
      expect(BackupData.decode('discrete', valid), isNotNull);

      // Not JSON / wrong shape.
      expect(BackupData.decode('discrete', 'not json'), isNull);
      expect(BackupData.decode('discrete', '{"columns": "x", "selectedStats": [], "precision": 3}'), isNull);
      // Unknown kind.
      expect(BackupData.decode('histogram', valid), isNull);
      // Wrong number of columns for the kind, or columns of different lengths.
      expect(BackupData.decode('continuous', valid), isNull);
      expect(BackupData.decode('discrete', '{"columns": [[1, 2], [3]], "selectedStats": [], "precision": 3}'), isNull);
      // A stat option that doesn't exist (for this kind).
      expect(BackupData.decode('discrete', '{"columns": [[1, 2], [3, 4]], "selectedStats": ["nope"], "precision": 3}'), isNull);
      expect(BackupData.decode('qualitative', '{"columns": [["a", "b"], [3, 4]], "selectedStats": ["median"], "precision": 3}'), isNull);
    });
  });
}
