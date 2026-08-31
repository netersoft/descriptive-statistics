import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../services/di/locator.dart';
import '../../services/shared_preferences/keys.dart';
import '../../services/shared_preferences/service.dart';
import '../../stats/discrete_stats.dart';
import '../../stats/stats_exceptions.dart';

part 'discrete_provider.g.dart';

/// The checkbox groups the legacy Discrete Variables screen exposes. Charts
/// are their own toggle, same as the legacy "courbe" checkbox.
enum DiscreteStatOption { mean, median, quartiles, mode, variance, covariance, standardDeviation, coefficientOfVariation, charts }

/// Why [DiscreteCalculator.calculate] could not produce a result.
enum CalculationError { insufficientData, emptyField, syntaxError }

class DiscreteCalculatorState {
  final Set<DiscreteStatOption> selectedStats;
  final bool showCalculations;
  final DiscreteStatsResult? result;

  const DiscreteCalculatorState({
    required this.selectedStats,
    this.showCalculations = false,
    this.result,
  });

  bool get isSelected => selectedStats.length == DiscreteStatOption.values.length;

  DiscreteCalculatorState copyWith({
    Set<DiscreteStatOption>? selectedStats,
    bool? showCalculations,
    DiscreteStatsResult? result,
  }) => DiscreteCalculatorState(
    selectedStats: selectedStats ?? this.selectedStats,
    showCalculations: showCalculations ?? this.showCalculations,
    result: result ?? this.result,
  );
}

@riverpod
class DiscreteCalculator extends _$DiscreteCalculator {
  @override
  DiscreteCalculatorState build() => DiscreteCalculatorState(selectedStats: DiscreteStatOption.values.toSet());

  void toggleStat(DiscreteStatOption option, bool selected) {
    final updated = Set<DiscreteStatOption>.from(state.selectedStats);
    if (selected) {
      updated.add(option);
    } else {
      updated.remove(option);
    }
    state = state.copyWith(selectedStats: updated);
  }

  void toggleAll(bool selected) {
    state = state.copyWith(selectedStats: selected ? DiscreteStatOption.values.toSet() : <DiscreteStatOption>{});
  }

  void toggleShowCalculations() {
    state = state.copyWith(showCalculations: !state.showCalculations);
  }

  int get decimalPrecision => locator<SharedPreferencesService>().getInt(PrefKeys.decimalPrecision, defaultValue: 3) ?? 3;

  /// Parses [xiText]/[niText] (one entry per row) and computes the stats,
  /// storing the result in state on success. Returns the failure reason on
  /// error, or null on success.
  CalculationError? calculate(List<String> xiText, List<String> niText) {
    if (xiText.length < 2) {
      return CalculationError.insufficientData;
    }

    final xi = <double>[];
    final ni = <double>[];
    for (var i = 0; i < xiText.length; i++) {
      if (xiText[i].trim().isEmpty || niText[i].trim().isEmpty) {
        return CalculationError.emptyField;
      }

      final parsedXi = double.tryParse(xiText[i]);
      final parsedNi = double.tryParse(niText[i]);
      if (parsedXi == null || parsedNi == null) {
        return CalculationError.syntaxError;
      }
      xi.add(parsedXi);
      ni.add(parsedNi);
    }

    try {
      state = state.copyWith(result: computeDiscreteStats(xi, ni, precision: decimalPrecision));
      return null;
    } on StatsInputException catch (e) {
      return e.reason == StatsErrorReason.insufficientData ? CalculationError.insufficientData : CalculationError.syntaxError;
    }
  }
}
