import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../stats/qualitative_stats.dart';
import '../../stats/stats_exceptions.dart';
import '../../tools/functions/number_parsing.dart';
import '../settings/settings_provider.dart';
import 'calculator_types.dart';

part 'qualitative_provider.g.dart';

class QualitativeCalculatorState {
  final Set<QualitativeStatOption> selectedStats;
  final bool showCalculations;
  final QualitativeStatsResult? result;

  /// The rows a backup last filled the calculator with (see `load`), for
  /// the screen to copy into its entry fields; [loadCount] bumps on every
  /// load so the screen can tell a new one from one it already applied.
  final List<List<String>>? loadedRows;
  final int loadCount;

  /// Whether the screen's entry rows hold any text, as it last reported --
  /// loading a backup over them asks for confirmation first.
  final bool hasEntries;

  const QualitativeCalculatorState({
    required this.selectedStats,
    this.showCalculations = false,
    this.result,
    this.loadedRows,
    this.loadCount = 0,
    this.hasEntries = false,
  });

  QualitativeCalculatorState copyWith({
    Set<QualitativeStatOption>? selectedStats,
    bool? showCalculations,
    QualitativeStatsResult? result,
    bool? hasEntries,
  }) => QualitativeCalculatorState(
    selectedStats: selectedStats ?? this.selectedStats,
    showCalculations: showCalculations ?? this.showCalculations,
    result: result ?? this.result,
    loadedRows: loadedRows,
    loadCount: loadCount,
    hasEntries: hasEntries ?? this.hasEntries,
  );
}

@Riverpod(keepAlive: true)
class QualitativeCalculator extends _$QualitativeCalculator {
  @override
  QualitativeCalculatorState build() => QualitativeCalculatorState(selectedStats: QualitativeStatOption.values.toSet());

  void toggleStat(QualitativeStatOption option, bool selected) {
    final updated = Set<QualitativeStatOption>.from(state.selectedStats);
    if (selected) {
      updated.add(option);
    } else {
      updated.remove(option);
    }
    state = state.copyWith(selectedStats: updated);
  }

  void toggleAll(bool selected) {
    state = state.copyWith(
      selectedStats: selected ? QualitativeStatOption.values.toSet() : <QualitativeStatOption>{},
    );
  }

  void toggleShowCalculations() {
    state = state.copyWith(showCalculations: !state.showCalculations);
  }

  void setHasEntries(bool hasEntries) {
    if (hasEntries != state.hasEntries) state = state.copyWith(hasEntries: hasEntries);
  }

  /// Fills the calculator with a saved backup's [rows] (one list of field
  /// texts per entry) and [selectedStats], then computes them as if the user
  /// had typed them and tapped Calculate. Returns the failure reason, if any.
  CalculationError? load(List<List<String>> rows, Set<QualitativeStatOption> selectedStats) {
    state = QualitativeCalculatorState(
      selectedStats: selectedStats,
      showCalculations: state.showCalculations,
      loadedRows: rows,
      loadCount: state.loadCount + 1,
      hasEntries: rows.isNotEmpty,
    );
    return calculate(rows.map((row) => row[0]).toList(), rows.map((row) => row[1]).toList());
  }

  /// Parses [modalityText]/[valueText] (one entry per row) and computes the
  /// stats, storing the result in state on success. Returns the failure
  /// reason on error, or null on success.
  CalculationError? calculate(List<String> modalityText, List<String> valueText) {
    if (modalityText.length < 2) {
      return CalculationError.insufficientData;
    }

    final values = <double>[];
    for (var i = 0; i < modalityText.length; i++) {
      if (modalityText[i].trim().isEmpty || valueText[i].trim().isEmpty) {
        return CalculationError.emptyField;
      }

      final parsedValue = parseDecimal(valueText[i]);
      if (parsedValue == null) {
        return CalculationError.syntaxError;
      }
      values.add(parsedValue);
    }

    try {
      final result = computeQualitativeStats(modalityText, values, precision: ref.read(settingsProvider).decimalPrecision);
      state = state.copyWith(result: result);
      return null;
    } on StatsInputException catch (e) {
      return calculationErrorFor(e.reason);
    }
  }
}
