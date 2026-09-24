import 'rounding.dart';
import 'stats_exceptions.dart';

/// Descriptive statistics for a qualitative (nominal) variable: modalities
/// with their aggregated effectifs, frequencies, and cumulative versions of
/// both.
class QualitativeStatsResult {
  /// Distinct modalities, in first-seen order.
  final List<String> modalities;

  /// Effectif (sum of values) per modality, aligned with [modalities].
  final List<double> effectifs;

  /// Frequency (% of the total) per modality, aligned with [modalities].
  final List<double> frequencies;
  final List<double> cumulativeEffectifs;
  final List<double> cumulativeFrequencies;

  final double total;

  /// `total / modalities.length` -- the mean of the aggregated effectifs.
  final double mean;

  /// The modality with the highest effectif (first one seen wins ties).
  final String modeModality;

  /// Every modality tied for the highest effectif, in first-seen order.
  /// Length 1 unless the distribution has no unique mode; [modeModality]
  /// is always [modeModalities].first.
  final List<String> modeModalities;

  bool get isModeUnique => modeModalities.length == 1;

  /// Decimal places every value above was rounded to.
  final int precision;

  const QualitativeStatsResult({
    required this.modalities,
    required this.effectifs,
    required this.frequencies,
    required this.cumulativeEffectifs,
    required this.cumulativeFrequencies,
    required this.total,
    required this.mean,
    required this.modeModality,
    required this.modeModalities,
    required this.precision,
  });
}

/// Computes descriptive statistics for a qualitative (nominal) variable given
/// parallel lists of [modalities] and their [values]. Values sharing the
/// same modality are aggregated together, in first-seen order. Mirrors
/// `QualitativeVariablesFragment.parsing()` from the legacy app.
QualitativeStatsResult computeQualitativeStats(
  List<String> modalities,
  List<double> values, {
  int precision = 3,
}) {
  if (modalities.length != values.length) {
    throw const StatsInputException(StatsErrorReason.lengthMismatch);
  }
  if (modalities.length < 2) {
    throw const StatsInputException(StatsErrorReason.insufficientData);
  }

  var total = 0.0;
  final distinctModalities = <String>[];
  final aggregated = <String, double>{};

  for (var i = 0; i < modalities.length; i++) {
    if (values[i] < 0) {
      throw const StatsInputException(StatsErrorReason.negativeEffectif);
    }
    total += values[i];

    final modality = modalities[i];
    if (!aggregated.containsKey(modality)) {
      distinctModalities.add(modality);
      aggregated[modality] = 0;
    }
    aggregated[modality] = aggregated[modality]! + values[i];
  }
  if (total == 0) {
    throw const StatsInputException(StatsErrorReason.zeroTotalEffectif);
  }

  final effectifs = distinctModalities.map((modality) => arrondi(aggregated[modality]!, precision)).toList();

  final frequencies = effectifs.map((effectif) => arrondi((effectif / total) * 100, precision)).toList();

  final cumulativeEffectifs = <double>[];
  final cumulativeFrequencies = <double>[];
  for (var i = 0; i < effectifs.length; i++) {
    cumulativeEffectifs.add(
      i == 0 ? arrondi(effectifs[i], precision) : arrondi(cumulativeEffectifs[i - 1] + effectifs[i], precision),
    );
    cumulativeFrequencies.add(
      i == 0 ? arrondi(frequencies[i], precision) : arrondi(cumulativeFrequencies[i - 1] + frequencies[i], precision),
    );
  }

  var modeValue = 0.0;
  final modeIndices = <int>[];
  for (var i = 0; i < effectifs.length; i++) {
    if (effectifs[i] > modeValue) {
      modeValue = effectifs[i];
      modeIndices
        ..clear()
        ..add(i);
    } else if (effectifs[i] == modeValue) {
      modeIndices.add(i);
    }
  }
  final modeModalities = [for (final i in modeIndices) distinctModalities[i]];
  final modeModality = modeModalities.first;

  final mean = arrondi(total / distinctModalities.length, precision);

  return QualitativeStatsResult(
    modalities: distinctModalities,
    effectifs: effectifs,
    frequencies: frequencies,
    cumulativeEffectifs: cumulativeEffectifs,
    cumulativeFrequencies: cumulativeFrequencies,
    total: arrondi(total, precision),
    mean: mean,
    modeModality: modeModality,
    modeModalities: modeModalities,
    precision: precision,
  );
}
