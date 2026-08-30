/// Structural reasons a stats computation can be rejected before any
/// arithmetic happens. Text-parsing failures (e.g. a non-numeric entry) are
/// the caller's concern -- this engine only deals with already-parsed
/// numbers.
enum StatsErrorReason {
  /// Fewer than two data rows were provided.
  insufficientData,

  /// The input lists don't all have the same length.
  lengthMismatch,

  /// A continuous class's upper bound is below its lower bound.
  negativeClassWidth,
}

/// Thrown by the `compute*Stats` functions when the input shape is invalid.
class StatsInputException implements Exception {
  final StatsErrorReason reason;

  const StatsInputException(this.reason);

  @override
  String toString() => 'StatsInputException(${reason.name})';
}
