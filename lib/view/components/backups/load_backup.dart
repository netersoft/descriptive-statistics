import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/backups/backup_data.dart';
import '../../../core/providers/calculators/calculator_types.dart';
import '../../../core/providers/calculators/continuous_provider.dart';
import '../../../core/providers/calculators/discrete_provider.dart';
import '../../../core/providers/calculators/qualitative_provider.dart';
import '../../../core/providers/main/home_provider.dart';
import '../../../core/services/i18n/translations.g.dart';
import '../../../core/stats/rounding.dart';
import '../../../core/tools/functions/number_parsing.dart';

/// Fills the calculator [data] comes from with its values and selected
/// stats, recomputes them, and switches to that calculator's tab -- so the
/// user can pick a saved calculation back up and change it.
///
/// The values are written the way the user would type them in the current
/// language (decimal comma or point), and recomputed with the current
/// decimal precision setting, like any other calculation.
void loadBackupIntoCalculator(WidgetRef ref, BackupData data) {
  final separator = decimalSeparatorForLocale(LocaleSettings.currentLocale.languageCode);
  // Modalities are stored as strings, every other column as numbers.
  String cell(Object value) => value is num ? noZero(value.toDouble(), decimalSeparator: separator) : value as String;

  final rows = [
    for (var i = 0; i < data.columns.first.length; i++) [for (final column in data.columns) cell(column[i])],
  ];

  switch (data.kind) {
    case BackupKind.discrete:
      ref.read(discreteCalculatorProvider.notifier).load(rows, {
        for (final name in data.selectedStats) StatOption.values.byName(name),
      });
      ref.read(homeProvider.notifier).tabIndex = HomeTab.discrete;
    case BackupKind.continuous:
      ref.read(continuousCalculatorProvider.notifier).load(rows, {
        for (final name in data.selectedStats) StatOption.values.byName(name),
      });
      ref.read(homeProvider.notifier).tabIndex = HomeTab.continuous;
    case BackupKind.qualitative:
      ref.read(qualitativeCalculatorProvider.notifier).load(rows, {
        for (final name in data.selectedStats) QualitativeStatOption.values.byName(name),
      });
      ref.read(homeProvider.notifier).tabIndex = HomeTab.qualitative;
  }
}
