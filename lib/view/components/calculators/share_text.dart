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
String buildDiscreteShareText(DiscreteStatsResult r, Set<StatOption> selected) => [
  t.appNameAlt,
  '',
  'Xi: ${r.xi.map(_fmt).join(', ')}',
  'Ni: ${r.ni.map(_fmt).join(', ')}',
  '',
  ...discreteResultLines(r, selected),
].join('\n');

/// One line per selected result ("MOYENNE: X = 3"), shared by the text
/// summary and the PDF export.
List<String> discreteResultLines(DiscreteStatsResult r, Set<StatOption> selected) {
  final lines = <String>[];

  if (selected.contains(StatOption.mean)) {
    lines.add('${t.meanSectionTitle}: X = ${_fmt(r.weightedMean)}');
  }
  if (selected.contains(StatOption.mode)) {
    final modeText = r.isModeUnique ? _fmt(r.mode) : r.modes.map(_fmt).join(', ');
    lines.add('${t.modeSectionTitle}: Mo = $modeText${r.isModeUnique ? '' : ' (${t.multipleModesNote})'}');
  }
  if (selected.contains(StatOption.median)) {
    lines.add('${t.medianSectionTitle}: Me = ${_fmt(r.median)}');
  }
  if (selected.contains(StatOption.quartiles)) {
    lines
      ..add(
        '${t.quartilesSectionTitle}: Q1 = ${_fmt(r.firstQuartile)}, Q3 = ${_fmt(r.thirdQuartile)}, '
        '${t.interQuartLabel} = ${_fmt(r.interquartileRange)}',
      )
      ..add('${t.decilesSectionTitle}: D1 = ${_fmt(r.firstDecile)}, D9 = ${_fmt(r.ninthDecile)}');
  }
  if (selected.contains(StatOption.variance)) {
    lines.add('${t.varianceSectionTitle}: ${_fmt(r.variance)}');
  }
  if (selected.contains(StatOption.covariance)) {
    lines
      ..add('${t.covarianceSectionTitle}: ${_fmt(r.covariance)}')
      ..add('${t.correlationSectionTitle}: ${r.isCorrelationDefined ? _fmt(r.correlation) : t.undefinedValue}');
  }
  if (selected.contains(StatOption.standardDeviation)) {
    lines
      ..add('${t.standardDeviationSectionTitle}: ${_fmt(r.standardDeviation)}')
      ..add('${t.standardErrorSectionTitle}: ${r.isStandardErrorDefined ? _fmt(r.standardError) : t.undefinedValue}');
  }
  if (selected.contains(StatOption.coefficientOfVariation)) {
    lines.add(
      r.isCoefficientOfVariationDefined
          ? '${t.coefficientOfVariationSectionTitle}: ${_fmt(r.coefficientOfVariation)}% '
                '(${r.isHomogeneous ? t.distribHomo : t.distribHetero})'
          : '${t.coefficientOfVariationSectionTitle}: ${t.undefinedValue}',
    );
  }
  lines.add('${t.rangeSectionTitle}: ${_fmt(r.range)}');

  return lines;
}

String buildContinuousShareText(
  ContinuousStatsResult r,
  List<double> l1,
  List<double> l2,
  Set<StatOption> selected,
) => [
  t.appNameAlt,
  '',
  'L1: ${l1.map(_fmt).join(', ')}',
  'L2: ${l2.map(_fmt).join(', ')}',
  'Ni: ${r.ni.map(_fmt).join(', ')}',
  '',
  ...continuousResultLines(r, selected),
].join('\n');

/// See [discreteResultLines].
List<String> continuousResultLines(ContinuousStatsResult r, Set<StatOption> selected) {
  final lines = <String>[];

  if (selected.contains(StatOption.mean)) {
    lines.add('${t.meanSectionTitle}: X = ${_fmt(r.weightedMean)}');
  }
  if (selected.contains(StatOption.mode)) {
    lines.add('${t.modeSectionTitle}: Mo = ${_fmt(r.mode)}${r.isModeUnique ? '' : ' (${t.multipleModesNote})'}');
  }
  if (selected.contains(StatOption.median)) {
    lines.add('${t.medianSectionTitle}: Me = ${_fmt(r.median)}');
  }
  if (selected.contains(StatOption.quartiles)) {
    lines
      ..add(
        '${t.quartilesSectionTitle}: Q1 = ${_fmt(r.firstQuartile)}, Q3 = ${_fmt(r.thirdQuartile)}, '
        '${t.interQuartLabel} = ${_fmt(r.interquartileRange)}',
      )
      ..add('${t.decilesSectionTitle}: D1 = ${_fmt(r.firstDecile)}, D9 = ${_fmt(r.ninthDecile)}');
  }
  if (selected.contains(StatOption.variance)) {
    lines.add('${t.varianceSectionTitle}: ${_fmt(r.variance)}');
  }
  if (selected.contains(StatOption.covariance)) {
    lines
      ..add('${t.covarianceSectionTitle}: ${_fmt(r.covariance)}')
      ..add('${t.correlationSectionTitle}: ${r.isCorrelationDefined ? _fmt(r.correlation) : t.undefinedValue}');
  }
  if (selected.contains(StatOption.standardDeviation)) {
    lines
      ..add('${t.standardDeviationSectionTitle}: ${_fmt(r.standardDeviation)}')
      ..add('${t.standardErrorSectionTitle}: ${r.isStandardErrorDefined ? _fmt(r.standardError) : t.undefinedValue}');
  }
  if (selected.contains(StatOption.coefficientOfVariation)) {
    lines.add(
      r.isCoefficientOfVariationDefined
          ? '${t.coefficientOfVariationSectionTitle}: ${_fmt(r.coefficientOfVariation)}% '
                '(${r.isHomogeneous ? t.distribHomo : t.distribHetero})'
          : '${t.coefficientOfVariationSectionTitle}: ${t.undefinedValue}',
    );
  }
  lines.add('${t.rangeSectionTitle}: ${_fmt(r.range)}');

  return lines;
}

String buildQualitativeShareText(QualitativeStatsResult r, Set<QualitativeStatOption> selected) => [
  t.appNameAlt,
  '',
  '${t.tableModalities}: ${r.modalities.join(', ')}',
  '${t.tableEffectifs}: ${r.effectifs.map(_fmt).join(', ')}',
  '${t.effectifTotal}: ${_fmt(r.total)}',
  '',
  ...qualitativeResultLines(r, selected),
].join('\n');

/// See [discreteResultLines].
List<String> qualitativeResultLines(QualitativeStatsResult r, Set<QualitativeStatOption> selected) {
  final lines = <String>[];

  if (selected.contains(QualitativeStatOption.mean)) {
    lines.add('${t.meanSectionTitle}: X = ${_fmt(r.mean)}');
  }
  if (selected.contains(QualitativeStatOption.mode)) {
    final modeText = r.isModeUnique ? r.modeModality : r.modeModalities.join(', ');
    lines.add('${t.modeSectionTitle}: Mo = $modeText${r.isModeUnique ? '' : ' (${t.multipleModesNote})'}');
  }

  return lines;
}

String _fmt(double v) => noZero(v, decimalSeparator: decimalSeparatorForLocale(LocaleSettings.currentLocale.languageCode));
