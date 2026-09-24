import 'dart:convert';

import '../../providers/calculators/calculator_types.dart';

/// Which calculator a backup comes from.
enum BackupKind { discrete, continuous, qualitative }

/// What a backup needs to recompute its calculation later -- and so to be
/// rendered in whatever language the app is using at that point, rather
/// than frozen in the one it was saved in.
///
/// [columns] holds the calculator's values as the result reports them
/// (already sorted/aggregated, which recomputes to the same stats):
/// - discrete: `[xi, ni]`
/// - continuous: `[l1, l2, ni]`
/// - qualitative: `[modalities, effectifs]`
class BackupData {
  final BackupKind kind;
  final List<List<Object>> columns;

  /// Names of the selected `StatOption`/`QualitativeStatOption` values.
  final List<String> selectedStats;

  final int precision;

  const BackupData({required this.kind, required this.columns, required this.selectedStats, required this.precision});

  List<double> numbers(int column) => [for (final value in columns[column]) (value as num).toDouble()];

  List<String> strings(int column) => [for (final value in columns[column]) value as String];

  String encode() => jsonEncode({'columns': columns, 'selectedStats': selectedStats, 'precision': precision});

  /// Rebuilds the data stored as a backup's `kind`/`data` fields, or null
  /// when they're missing (older backups) or not in the expected shape.
  static BackupData? decode(String? kind, String? data) {
    if (kind == null || data == null) return null;
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      final columns = [for (final column in json['columns'] as List) List<Object>.from(column as List)];
      final expectedColumns = kind == BackupKind.continuous.name ? 3 : 2;
      if (columns.length != expectedColumns || columns.any((column) => column.length != columns.first.length)) return null;

      final backupKind = BackupKind.values.byName(kind);
      final selectedStats = List<String>.from(json['selectedStats'] as List);
      final knownStats = backupKind == BackupKind.qualitative ? QualitativeStatOption.values : StatOption.values;
      if (!selectedStats.every((name) => knownStats.any((option) => option.name == name))) return null;

      return BackupData(kind: backupKind, columns: columns, selectedStats: selectedStats, precision: json['precision'] as int);
    } on Object {
      // Anything unexpected (bad JSON, wrong types, unknown kind): treat it
      // like an older backup and fall back to its stored HTML.
      return null;
    }
  }
}
