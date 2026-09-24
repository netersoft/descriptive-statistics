import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../services/di/locator.dart';
import '../../services/shared_preferences/keys.dart';
import '../../services/shared_preferences/service.dart';
import '../../stats/qualitative_stats.dart';
import '../../stats/stats_exceptions.dart';
import '../../tools/functions/number_parsing.dart';
import 'calculator_types.dart';

part 'qualitative_provider.g.dart';

class QualitativeCalculatorState {
  final Set<QualitativeStatOption> selectedStats;
  final bool showCalculations;
  final QualitativeStatsResult? result;

  const QualitativeCalculatorState({
    required this.selectedStats,
    this.showCalculations = false,
    this.result,
  });

  bool get isSelected => selectedStats.length == QualitativeStatOption.values.length;

  QualitativeCalculatorState copyWith({
    Set<QualitativeStatOption>? selectedStats,
    bool? showCalculations,
    QualitativeStatsResult? result,
  }) => QualitativeCalculatorState(
    selectedStats: selectedStats ?? this.selectedStats,
    showCalculations: showCalculations ?? this.showCalculations,
    result: result ?? this.result,
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

  int _decimalPrecision() => locator<SharedPreferencesService>().getInt(PrefKeys.decimalPrecision, defaultValue: 3) ?? 3;

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
      final result = computeQualitativeStats(modalityText, values, precision: _decimalPrecision());
      state = state.copyWith(result: result);
      return null;
    } on StatsInputException catch (e) {
      return switch (e.reason) {
        StatsErrorReason.insufficientData => CalculationError.insufficientData,
        StatsErrorReason.negativeEffectif ||
        StatsErrorReason.zeroTotalEffectif ||
        StatsErrorReason.invalidClassWidth ||
        StatsErrorReason.overlappingClasses => CalculationError.invalidValue,
        StatsErrorReason.lengthMismatch => CalculationError.syntaxError,
      };
    }
  }
}
