import 'package:intl/intl.dart';

import '../../../core/data/backups/backup_data.dart';
import '../../../core/models/backup_model.dart';
import '../../../core/providers/calculators/calculator_types.dart';
import '../../../core/stats/continuous_stats.dart';
import '../../../core/stats/discrete_stats.dart';
import '../../../core/stats/qualitative_stats.dart';
import '../../../core/stats/rounding.dart';
import '../../../core/stats/stats_exceptions.dart';
import '../../../core/tools/functions/number_parsing.dart';
import '../calculators/calculator_actions.dart';
import '../calculators/continuous_explanation.dart';
import '../calculators/discrete_explanation.dart';
import '../calculators/qualitative_explanation.dart';

/// The backup's step-by-step explanation, recomputed from its stored data
/// so it's shown in the app's current language. Falls back to the HTML
/// saved with it for backups that predate that data.
String backupExplanationHtml(Backup backup) {
  final data = BackupData.decode(backup.kind, backup.data);
  if (data == null) return backup.resolutionHtml;

  try {
    return switch (data.kind) {
      BackupKind.discrete => buildDiscreteExplanationHtml(
        computeDiscreteStats(data.numbers(0), data.numbers(1), precision: data.precision),
        {for (final name in data.selectedStats) StatOption.values.byName(name)},
      ),
      BackupKind.continuous => buildContinuousExplanationHtml(
        computeContinuousStats(data.numbers(0), data.numbers(1), data.numbers(2), precision: data.precision),
        data.numbers(0),
        data.numbers(1),
        {for (final name in data.selectedStats) StatOption.values.byName(name)},
      ),
      BackupKind.qualitative => buildQualitativeExplanationHtml(
        computeQualitativeStats(data.strings(0), data.numbers(1), precision: data.precision),
        {for (final name in data.selectedStats) QualitativeStatOption.values.byName(name)},
      ),
    };
  } on StatsInputException {
    return backup.resolutionHtml;
  }
}

/// Labels and values for the backup's mini bar chart, or null when they
/// can't be read. Qualitative backups are labelled with their modalities
/// when their data is available (older ones only stored modality indices).
(List<String>, List<double>)? backupChartData(Backup backup, String languageCode) {
  final data = BackupData.decode(backup.kind, backup.data);
  if (data?.kind == BackupKind.qualitative) {
    return (data!.strings(0), data.numbers(1));
  }

  if (backup.xi.isEmpty || backup.ni.isEmpty) return null;

  // Xi are stored as Dart's raw double.toString() ("1.0", "4.5"): show
  // them the way the calculators do ("1", "4,5" in fr/de/es/pt).
  final separator = decimalSeparatorForLocale(languageCode);
  final labels = [
    for (final raw in backup.xi.split('_'))
      if (double.tryParse(raw) case final value?) noZero(value, decimalSeparator: separator) else raw,
  ];
  final values = backup.ni.split('_').map(double.tryParse).toList();
  if (values.length != labels.length || values.any((v) => v == null)) return null;

  return (labels, values.cast<double>());
}

/// The save date in [languageCode]'s own date format when the backup
/// recorded its save time, else the date string stored with it.
String backupDateLabel(Backup backup, String languageCode) {
  final createdAt = backup.createdAt;
  return createdAt == null ? backup.date : dateTimeLabel(createdAt, languageCode);
}

/// [date] in [languageCode]'s own date format, with the time.
String dateTimeLabel(DateTime date, String languageCode) {
  try {
    return DateFormat.yMd(languageCode).add_Hm().format(date);
  } on Exception {
    // Locale date symbols not loaded (they are once MaterialApp's
    // localization delegates have run).
    return formatBackupDate(date);
  }
}
