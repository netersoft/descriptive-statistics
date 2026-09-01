import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../services/di/locator.dart';
import '../../services/shared_preferences/keys.dart';
import '../../services/shared_preferences/service.dart';
import '../../stats/continuous_stats.dart';
import '../../stats/stats_exceptions.dart';
import '../../tools/functions/number_parsing.dart';
import 'calculator_types.dart';

part 'continuous_provider.g.dart';

class ContinuousCalculatorState {
  final Set<StatOption> selectedStats;
  final bool showCalculations;
  final ContinuousStatsResult? result;

  /// The raw (unrounded) class bounds behind [result], kept around because
  /// the explanation panel's mode/median interpolation formulas need L1 and
  /// the class width -- neither of which the result exposes on its own.
  final List<double> l1;
  final List<double> l2;

  const ContinuousCalculatorState({
    required this.selectedStats,
    this.showCalculations = false,
    this.result,
    this.l1 = const [],
    this.l2 = const [],
  });

  bool get isSelected => selectedStats.length == StatOption.values.length;

  ContinuousCalculatorState copyWith({
    Set<StatOption>? selectedStats,
    bool? showCalculations,
    ContinuousStatsResult? result,
    List<double>? l1,
    List<double>? l2,
  }) => ContinuousCalculatorState(
    selectedStats: selectedStats ?? this.selectedStats,
    showCalculations: showCalculations ?? this.showCalculations,
    result: result ?? this.result,
    l1: l1 ?? this.l1,
    l2: l2 ?? this.l2,
  );
}

@Riverpod(keepAlive: true)
class ContinuousCalculator extends _$ContinuousCalculator {
  @override
  ContinuousCalculatorState build() => ContinuousCalculatorState(selectedStats: StatOption.values.toSet());

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

  int get decimalPrecision => locator<SharedPreferencesService>().getInt(PrefKeys.decimalPrecision, defaultValue: 3) ?? 3;

  /// Parses [l1Text]/[l2Text]/[niText] (one entry per row) and computes the
  /// stats, storing the result in state on success. Returns the failure
  /// reason on error, or null on success.
  CalculationError? calculate(List<String> l1Text, List<String> l2Text, List<String> niText) {
    if (l1Text.length < 2) {
      return CalculationError.insufficientData;
    }

    final l1 = <double>[];
    final l2 = <double>[];
    final ni = <double>[];
    for (var i = 0; i < l1Text.length; i++) {
      if (l1Text[i].trim().isEmpty || l2Text[i].trim().isEmpty || niText[i].trim().isEmpty) {
        return CalculationError.emptyField;
      }

      final parsedL1 = parseDecimal(l1Text[i]);
      final parsedL2 = parseDecimal(l2Text[i]);
      final parsedNi = parseDecimal(niText[i]);
      if (parsedL1 == null || parsedL2 == null || parsedNi == null) {
        return CalculationError.syntaxError;
      }
      l1.add(parsedL1);
      l2.add(parsedL2);
      ni.add(parsedNi);
    }

    // Sort by L1 ascending here too (mirroring the engine's own internal
    // sort) so the indices in [result] (modalClassIndex, medianClassIndex,
    // modalClassIndices) correctly refer to positions in the stored l1/l2 --
    // otherwise the explanation panel would label the wrong class when rows
    // aren't entered in ascending order.
    final order = List<int>.generate(l1.length, (i) => i)..sort((a, b) => l1[a].compareTo(l1[b]));
    final sortedL1 = [for (final i in order) l1[i]];
    final sortedL2 = [for (final i in order) l2[i]];
    final sortedNi = [for (final i in order) ni[i]];

    try {
      final result = computeContinuousStats(sortedL1, sortedL2, sortedNi, precision: decimalPrecision);
      state = state.copyWith(result: result, l1: sortedL1, l2: sortedL2);
      return null;
    } on StatsInputException catch (e) {
      return switch (e.reason) {
        StatsErrorReason.insufficientData => CalculationError.insufficientData,
        StatsErrorReason.negativeEffectif || StatsErrorReason.zeroTotalEffectif || StatsErrorReason.invalidClassWidth => CalculationError.invalidValue,
        StatsErrorReason.lengthMismatch => CalculationError.syntaxError,
      };
    }
  }
}
