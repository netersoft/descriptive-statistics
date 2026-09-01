import 'dart:convert';

import '../../models/backup_model.dart';

/// Serializes backups to a portable JSON document -- lets a user carry their
/// saved calculations across devices or keep an external copy, since Hive's
/// storage is local-only.
String exportBackupsToJson(List<Backup> backups) => const JsonEncoder.withIndent('  ').convert({
  'app': 'Statistique Descriptive',
  'version': 1,
  'backups': [
    for (final backup in backups)
      {
        'name': backup.name,
        'resolutionHtml': backup.resolutionHtml,
        'xi': backup.xi,
        'ni': backup.ni,
        'date': backup.date,
      },
  ],
});

/// Parses a JSON document produced by [exportBackupsToJson]. Throws a
/// [FormatException] if [content] isn't valid JSON or doesn't match the
/// expected shape, so the caller can surface a clear error instead of
/// importing partial/garbage data.
List<Backup> parseBackupsJson(String content) {
  final Object? decoded;
  try {
    decoded = jsonDecode(content);
  } on FormatException {
    throw const FormatException('Not valid JSON');
  }

  if (decoded is! Map<String, dynamic> || decoded['backups'] is! List) {
    throw const FormatException('Missing or invalid "backups" array');
  }

  return [for (final entry in decoded['backups'] as List) _backupFromJson(entry)];
}

Backup _backupFromJson(Object? entry) {
  if (entry is! Map<String, dynamic>) {
    throw const FormatException('Backup entry is not an object');
  }
  final name = entry['name'];
  final resolutionHtml = entry['resolutionHtml'];
  final xi = entry['xi'];
  final ni = entry['ni'];
  final date = entry['date'];
  if (name is! String || resolutionHtml is! String || xi is! String || ni is! String || date is! String) {
    throw const FormatException('Backup entry is missing a required field');
  }
  return Backup(name: name, resolutionHtml: resolutionHtml, xi: xi, ni: ni, date: date);
}
