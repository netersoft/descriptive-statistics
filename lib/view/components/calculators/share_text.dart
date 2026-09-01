import '../../../core/providers/calculators/calculator_types.dart';
import '../../../core/services/i18n/translations.g.dart';
import '../../../core/stats/continuous_stats.dart';
import '../../../core/stats/discrete_stats.dart';
import '../../../core/stats/qualitative_stats.dart';
import '../../../core/stats/rounding.dart';
import '../../../core/tools/functions/number_parsing.dart';

/// Plain-text summaries of a calculation result, gated by which stats were
/// selected -- for sharing outside the app (e.g. to a teacher), unlike the
/// HTML explanation panels which are only ever rendered on-screen.
String buildDiscreteShareText(DiscreteStatsResult r, Set<StatOption> selected) {
  final sep = decimalSeparatorForLocale(LocaleSettings.currentLocale.languageCode);
  String fmt(double v) => noZero(v, decimalSeparator: sep);

  final buffer = StringBuffer()
    ..writeln(t.appNameAlt)
    ..writeln()
    ..writeln('Xi: ${r.xi.map(fmt).join(', ')}')
    ..writeln('Ni: ${r.ni.map(fmt).join(', ')}')
    ..writeln();

  if (selected.contains(StatOption.mean)) {
    buffer.writeln('${t.meanSectionTitle}: X = ${fmt(r.weightedMean)}');
  }
  if (selected.contains(StatOption.mode)) {
    final modeText = r.isModeUnique ? fmt(r.mode) : r.modes.map(fmt).join(', ');
    buffer.writeln('${t.modeSectionTitle}: Mo = $modeText${r.isModeUnique ? '' : ' (${t.multipleModesNote})'}');
  }
  if (selected.contains(StatOption.median)) {
    buffer.writeln('${t.medianSectionTitle}: Me = ${fmt(r.median)}');
  }
  if (selected.contains(StatOption.quartiles)) {
    buffer
      ..writeln(
        '${t.quartilesSectionTitle}: Q1 = ${fmt(r.firstQuartile)}, Q3 = ${fmt(r.thirdQuartile)}, '
        '${t.interQuartLabel} = ${fmt(r.interquartileRange)}',
      )
      ..writeln('${t.decilesSectionTitle}: D1 = ${fmt(r.firstDecile)}, D9 = ${fmt(r.ninthDecile)}');
  }
  if (selected.contains(StatOption.variance)) {
    buffer.writeln('${t.varianceSectionTitle}: ${fmt(r.variance)}');
  }
  if (selected.contains(StatOption.covariance)) {
    buffer
      ..writeln('${t.covarianceSectionTitle}: ${fmt(r.covariance)}')
      ..writeln('${t.correlationSectionTitle}: ${fmt(r.correlation)}');
  }
  if (selected.contains(StatOption.standardDeviation)) {
    buffer
      ..writeln('${t.standardDeviationSectionTitle}: ${fmt(r.standardDeviation)}')
      ..writeln('${t.standardErrorSectionTitle}: ${fmt(r.standardError)}');
  }
  if (selected.contains(StatOption.coefficientOfVariation)) {
    buffer.writeln(
      '${t.coefficientOfVariationSectionTitle}: ${fmt(r.coefficientOfVariation)}% '
      '(${r.isHomogeneous ? t.distribHomo : t.distribHetero})',
    );
  }
  buffer.write('${t.rangeSectionTitle}: ${fmt(r.range)}');

  return buffer.toString();
}

String buildContinuousShareText(
  ContinuousStatsResult r,
  List<double> l1,
  List<double> l2,
  Set<StatOption> selected,
) {
  final sep = decimalSeparatorForLocale(LocaleSettings.currentLocale.languageCode);
  String fmt(double v) => noZero(v, decimalSeparator: sep);

  final buffer = StringBuffer()
    ..writeln(t.appNameAlt)
    ..writeln()
    ..writeln('L1: ${l1.map(fmt).join(', ')}')
    ..writeln('L2: ${l2.map(fmt).join(', ')}')
    ..writeln('Ni: ${r.ni.map(fmt).join(', ')}')
    ..writeln();

  if (selected.contains(StatOption.mean)) {
    buffer.writeln('${t.meanSectionTitle}: X = ${fmt(r.weightedMean)}');
  }
  if (selected.contains(StatOption.mode)) {
    buffer.writeln('${t.modeSectionTitle}: Mo = ${fmt(r.mode)}${r.isModeUnique ? '' : ' (${t.multipleModesNote})'}');
  }
  if (selected.contains(StatOption.median)) {
    buffer.writeln('${t.medianSectionTitle}: Me = ${fmt(r.median)}');
  }
  if (selected.contains(StatOption.quartiles)) {
    buffer
      ..writeln(
        '${t.quartilesSectionTitle}: Q1 = ${fmt(r.firstQuartile)}, Q3 = ${fmt(r.thirdQuartile)}, '
        '${t.interQuartLabel} = ${fmt(r.interquartileRange)}',
      )
      ..writeln('${t.decilesSectionTitle}: D1 = ${fmt(r.firstDecile)}, D9 = ${fmt(r.ninthDecile)}');
  }
  if (selected.contains(StatOption.variance)) {
    buffer.writeln('${t.varianceSectionTitle}: ${fmt(r.variance)}');
  }
  if (selected.contains(StatOption.covariance)) {
    buffer
      ..writeln('${t.covarianceSectionTitle}: ${fmt(r.covariance)}')
      ..writeln('${t.correlationSectionTitle}: ${fmt(r.correlation)}');
  }
  if (selected.contains(StatOption.standardDeviation)) {
    buffer
      ..writeln('${t.standardDeviationSectionTitle}: ${fmt(r.standardDeviation)}')
      ..writeln('${t.standardErrorSectionTitle}: ${fmt(r.standardError)}');
  }
  if (selected.contains(StatOption.coefficientOfVariation)) {
    buffer.writeln(
      '${t.coefficientOfVariationSectionTitle}: ${fmt(r.coefficientOfVariation)}% '
      '(${r.isHomogeneous ? t.distribHomo : t.distribHetero})',
    );
  }
  buffer.write('${t.rangeSectionTitle}: ${fmt(r.range)}');

  return buffer.toString();
}

String buildQualitativeShareText(QualitativeStatsResult r, Set<QualitativeStatOption> selected) {
  final sep = decimalSeparatorForLocale(LocaleSettings.currentLocale.languageCode);
  String fmt(double v) => noZero(v, decimalSeparator: sep);

  final buffer = StringBuffer()
    ..writeln(t.appNameAlt)
    ..writeln()
    ..writeln('${t.tableModalities}: ${r.modalities.join(', ')}')
    ..writeln('${t.tableEffectifs}: ${r.effectifs.map(fmt).join(', ')}')
    ..writeln('${t.effectifTotal}: ${fmt(r.total)}')
    ..writeln();

  if (selected.contains(QualitativeStatOption.mean)) {
    buffer.writeln('${t.meanSectionTitle}: X = ${fmt(r.mean)}');
  }
  if (selected.contains(QualitativeStatOption.mode)) {
    final modeText = r.isModeUnique ? r.modeModality : r.modeModalities.join(', ');
    buffer.writeln('${t.modeSectionTitle}: Mo = $modeText${r.isModeUnique ? '' : ' (${t.multipleModesNote})'}');
  }

  return buffer.toString();
}
