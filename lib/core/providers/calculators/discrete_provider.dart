import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../stats/discrete_stats.dart';
import '../../stats/stats_exceptions.dart';
import '../../tools/functions/number_parsing.dart';
import '../settings/settings_provider.dart';
import 'calculator_types.dart';

part 'discrete_provider.g.dart';

class DiscreteCalculatorState {
  final Set<StatOption> selectedStats;
  final bool showCalculations;
  final DiscreteStatsResult? result;

  const DiscreteCalculatorState({
    required this.selectedStats,
    this.showCalculations = false,
    this.result,
  });

  DiscreteCalculatorState copyWith({
    Set<StatOption>? selectedStats,
    bool? showCalculations,
    DiscreteStatsResult? result,
  }) => DiscreteCalculatorState(
    selectedStats: selectedStats ?? this.selectedStats,
    showCalculations: showCalculations ?? this.showCalculations,
    result: result ?? this.result,
  );
}

@Riverpod(keepAlive: true)
class DiscreteCalculator extends _$DiscreteCalculator {
  @override
  DiscreteCalculatorState build() => DiscreteCalculatorState(selectedStats: StatOption.values.toSet());

  void toggleStat(StatOption option, bool selected) {
    final updated = Set<StatOption>.from(state.selectedStats);
    if (selected) {
      updated.add(option);
    } else {
      updated.remove(option);
    }
    state = state.copyWith(selectedStats: updated);
  }

  void toggleAll(bool selected) {
    state = state.copyWith(selectedStats: selected ? StatOption.values.toSet() : <StatOption>{});
  }

  void toggleShowCalculations() {
    state = state.copyWith(showCalculations: !state.showCalculations);
  }

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

      final parsedXi = parseDecimal(xiText[i]);
      final parsedNi = parseDecimal(niText[i]);
      if (parsedXi == null || parsedNi == null) {
        return CalculationError.syntaxError;
      }
      xi.add(parsedXi);
      ni.add(parsedNi);
    }

    try {
      state = state.copyWith(result: computeDiscreteStats(xi, ni, precision: ref.read(settingsProvider).decimalPrecision));
      return null;
    } on StatsInputException catch (e) {
      return calculationErrorFor(e.reason);
    }
  }
}
