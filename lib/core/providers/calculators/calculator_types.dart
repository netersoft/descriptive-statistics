/// Checkbox groups shared by the Discrete and Continuous Variables screens
/// (Qualitative has a smaller, distinct set). Charts are their own toggle,
/// same as the legacy "courbe" checkbox.
enum StatOption { mean, median, quartiles, mode, variance, covariance, standardDeviation, coefficientOfVariation, charts }

/// Why a calculator provider's `calculate` could not produce a result.
enum CalculationError { insufficientData, emptyField, syntaxError }
