import '../../../core/providers/calculators/calculator_types.dart';
import '../../../core/services/i18n/translations.g.dart';
import '../../../core/stats/continuous_stats.dart';
import '../../../core/stats/discrete_stats.dart';
import '../../../core/stats/qualitative_stats.dart';
import '../../../core/stats/rounding.dart';

/// Plain-text summaries of a calculation result, gated by which stats were
/// selected -- for sharing outside the app (e.g. to a teacher), unlike the
/// HTML explanation panels which are only ever rendered on-screen.
String buildDiscreteShareText(DiscreteStatsResult r, Set<StatOption> selected) {
  final buffer = StringBuffer()
    ..writeln(t.appNameAlt)
    ..writeln()
    ..writeln('Xi: ${r.xi.map(noZero).join(', ')}')
    ..writeln('Ni: ${r.ni.map(noZero).join(', ')}')
    ..writeln();

  if (selected.contains(StatOption.mean)) {
    buffer.writeln('${t.meanSectionTitle}: X = ${noZero(r.weightedMean)}');
  }
  if (selected.contains(StatOption.mode)) {
    final modeText = r.isModeUnique ? noZero(r.mode) : r.modes.map(noZero).join(', ');
    buffer.writeln('${t.modeSectionTitle}: Mo = $modeText${r.isModeUnique ? '' : ' (${t.multipleModesNote})'}');
  }
  if (selected.contains(StatOption.median)) {
    buffer.writeln('${t.medianSectionTitle}: Me = ${noZero(r.median)}');
  }
  if (selected.contains(StatOption.quartiles)) {
    buffer
      ..writeln(
        '${t.quartilesSectionTitle}: Q1 = ${noZero(r.firstQuartile)}, Q3 = ${noZero(r.thirdQuartile)}, '
        '${t.interQuartLabel} = ${noZero(r.interquartileRange)}',
      )
      ..writeln('${t.decilesSectionTitle}: D1 = ${noZero(r.firstDecile)}, D9 = ${noZero(r.ninthDecile)}');
  }
  if (selected.contains(StatOption.variance)) {
    buffer.writeln('${t.varianceSectionTitle}: ${noZero(r.variance)}');
  }
  if (selected.contains(StatOption.covariance)) {
    buffer
      ..writeln('${t.covarianceSectionTitle}: ${noZero(r.covariance)}')
      ..writeln('${t.correlationSectionTitle}: ${noZero(r.correlation)}');
  }
  if (selected.contains(StatOption.standardDeviation)) {
    buffer
      ..writeln('${t.standardDeviationSectionTitle}: ${noZero(r.standardDeviation)}')
      ..writeln('${t.standardErrorSectionTitle}: ${noZero(r.standardError)}');
  }
  if (selected.contains(StatOption.coefficientOfVariation)) {
    buffer.writeln(
      '${t.coefficientOfVariationSectionTitle}: ${noZero(r.coefficientOfVariation)}% '
      '(${r.isHomogeneous ? t.distribHomo : t.distribHetero})',
    );
  }
  buffer.write('${t.rangeSectionTitle}: ${noZero(r.range)}');

  return buffer.toString();
}

String buildContinuousShareText(
  ContinuousStatsResult r,
  List<double> l1,
  List<double> l2,
  Set<StatOption> selected,
) {
  final buffer = StringBuffer()
    ..writeln(t.appNameAlt)
    ..writeln()
    ..writeln('L1: ${l1.map(noZero).join(', ')}')
    ..writeln('L2: ${l2.map(noZero).join(', ')}')
    ..writeln('Ni: ${r.ni.map(noZero).join(', ')}')
    ..writeln();

  if (selected.contains(StatOption.mean)) {
    buffer.writeln('${t.meanSectionTitle}: X = ${noZero(r.weightedMean)}');
  }
  if (selected.contains(StatOption.mode)) {
    buffer.writeln('${t.modeSectionTitle}: Mo = ${noZero(r.mode)}${r.isModeUnique ? '' : ' (${t.multipleModesNote})'}');
  }
  if (selected.contains(StatOption.median)) {
    buffer.writeln('${t.medianSectionTitle}: Me = ${noZero(r.median)}');
  }
  if (selected.contains(StatOption.quartiles)) {
    buffer
      ..writeln(
        '${t.quartilesSectionTitle}: Q1 = ${noZero(r.firstQuartile)}, Q3 = ${noZero(r.thirdQuartile)}, '
        '${t.interQuartLabel} = ${noZero(r.interquartileRange)}',
      )
      ..writeln('${t.decilesSectionTitle}: D1 = ${noZero(r.firstDecile)}, D9 = ${noZero(r.ninthDecile)}');
  }
  if (selected.contains(StatOption.variance)) {
    buffer.writeln('${t.varianceSectionTitle}: ${noZero(r.variance)}');
  }
  if (selected.contains(StatOption.covariance)) {
    buffer
      ..writeln('${t.covarianceSectionTitle}: ${noZero(r.covariance)}')
      ..writeln('${t.correlationSectionTitle}: ${noZero(r.correlation)}');
  }
  if (selected.contains(StatOption.standardDeviation)) {
    buffer
      ..writeln('${t.standardDeviationSectionTitle}: ${noZero(r.standardDeviation)}')
      ..writeln('${t.standardErrorSectionTitle}: ${noZero(r.standardError)}');
  }
  if (selected.contains(StatOption.coefficientOfVariation)) {
    buffer.writeln(
      '${t.coefficientOfVariationSectionTitle}: ${noZero(r.coefficientOfVariation)}% '
      '(${r.isHomogeneous ? t.distribHomo : t.distribHetero})',
    );
  }
  buffer.write('${t.rangeSectionTitle}: ${noZero(r.range)}');

  return buffer.toString();
}

String buildQualitativeShareText(QualitativeStatsResult r, Set<QualitativeStatOption> selected) {
  final buffer = StringBuffer()
    ..writeln(t.appNameAlt)
    ..writeln()
    ..writeln('${t.tableModalities}: ${r.modalities.join(', ')}')
    ..writeln('${t.tableEffectifs}: ${r.effectifs.map(noZero).join(', ')}')
    ..writeln('${t.effectifTotal}: ${noZero(r.total)}')
    ..writeln();

  if (selected.contains(QualitativeStatOption.mean)) {
    buffer.writeln('${t.meanSectionTitle}: X = ${noZero(r.mean)}');
  }
  if (selected.contains(QualitativeStatOption.mode)) {
    final modeText = r.isModeUnique ? r.modeModality : r.modeModalities.join(', ');
    buffer.writeln('${t.modeSectionTitle}: Mo = $modeText${r.isModeUnique ? '' : ' (${t.multipleModesNote})'}');
  }

  return buffer.toString();
}
