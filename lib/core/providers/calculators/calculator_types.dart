import '../../stats/stats_exceptions.dart';

/// Checkbox groups shared by the Discrete and Continuous Variables screens
/// (Qualitative has a smaller, distinct set). Charts are their own toggle,
/// same as the legacy "courbe" checkbox.
enum StatOption { mean, median, quartiles, mode, variance, covariance, standardDeviation, coefficientOfVariation, charts }

/// The smaller checkbox set the Qualitative Variables screen exposes --
/// nominal data doesn't have a median/quartiles/variance/etc.
enum QualitativeStatOption { mean, mode, charts }

/// Why a calculator provider's `calculate` could not produce a result.
enum CalculationError { insufficientData, emptyField, syntaxError, invalidValue, invalidClassWidth, overlappingClasses }

/// Why the stats engine rejected already-parsed input, as the calculators
/// report it to the user.
CalculationError calculationErrorFor(StatsErrorReason reason) => switch (reason) {
  StatsErrorReason.insufficientData => CalculationError.insufficientData,
  StatsErrorReason.negativeEffectif || StatsErrorReason.zeroTotalEffectif => CalculationError.invalidValue,
  StatsErrorReason.invalidClassWidth => CalculationError.invalidClassWidth,
  StatsErrorReason.overlappingClasses => CalculationError.overlappingClasses,
  StatsErrorReason.lengthMismatch => CalculationError.syntaxError,
};
