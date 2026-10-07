import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/providers/calculators/calculator_types.dart';
import '../../../core/services/i18n/translations.g.dart';
import '../../../core/stats/discrete_stats.dart';
import '../../../core/stats/rounding.dart';
import '../../../core/tools/functions/number_parsing.dart';
import '../misc/themed_html.dart';

/// Renders the step-by-step formula walkthrough for a [DiscreteStatsResult],
/// gated by which [StatOption]s are selected -- mirrors the legacy
/// app's HTML "resolution" panel, built the same way (per-checkbox HTML
/// fragments concatenated together) and rendered with the same formulas.
class DiscreteExplanation extends StatelessWidget {
  final DiscreteStatsResult result;
  final Set<StatOption> selectedStats;

  const DiscreteExplanation({required this.result, required this.selectedStats, super.key});

  @override
  Widget build(BuildContext context) => ThemedHtml(buildDiscreteExplanationHtml(result, selectedStats));
}

/// The intermediate sums below (xiniSum, covarianceSum, the two standard
/// deviations, ...) aren't part of [DiscreteStatsResult] -- it only exposes
/// final statistics -- but are cheap to recompute here from the already
/// rounded [DiscreteStatsResult.xi]/[DiscreteStatsResult.ni] purely for
/// display, reproducing exactly what the engine computed internally.
/// [precision] must match the value the result was computed with, so the
/// intermediate values shown here round the same way as the final stats
/// they lead into.
String buildDiscreteExplanationHtml(DiscreteStatsResult r, Set<StatOption> selected) {
  final precision = r.precision;
  final sep = decimalSeparatorForLocale(LocaleSettings.currentLocale.languageCode);
  String fmt(double v) => noZero(v, decimalSeparator: sep);

  final n = r.xi.length;
  final niSum = r.ni.reduce((a, b) => a + b);
  // Re-rounded (not just the raw sum of already-rounded rows) so summing
  // rows like 0.1 + 0.2 can't reintroduce binary floating-point noise into
  // the displayed intermediate value.
  final xiniSum = arrondi(r.xini.reduce((a, b) => a + b), precision);
  final xi2niSum = arrondi(r.xi2ni.reduce((a, b) => a + b), precision);

  final xMean = r.xi.reduce((a, b) => a + b) / n;
  final yMean = niSum / n;
  var covarianceSum = 0.0;
  var xSquares = 0.0;
  var ySquares = 0.0;
  for (var i = 0; i < n; i++) {
    final v2 = r.xi[i] - xMean;
    final v1 = r.ni[i] - yMean;
    covarianceSum += v2 * v1;
    xSquares += v2 * v2;
    ySquares += v1 * v1;
  }
  final xDeviation = math.sqrt(xSquares / (n - 1));
  final yDeviation = math.sqrt(ySquares / (n - 1));

  final buffer = StringBuffer();

  if (selected.contains(StatOption.mean)) {
    buffer.write('''
<b><font color='blue'><u>${t.meanSectionTitle}</u></font></b><br>
<font color='magenta'>${t.weightedMeanLabel}</font><br>
<b>X = &sum;XiNi / &sum;Ni</b><br>
X = ${fmt(xiniSum)} / ${fmt(niSum)}<br>
<font color='red'><b><u>X = ${fmt(r.weightedMean)}</u></b></font><br><br>
<font color='magenta'>${t.meanEffectifLabel}</font><br>
<b>N&#772; = &sum;Ni / n</b><br>
N&#772; = ${fmt(niSum)} / $n<br>
<font color='red'><b><u>N&#772; = ${fmt(r.meanEffectif)}</u></b></font><br><br>
''');
  }

  if (selected.contains(StatOption.mode)) {
    final modeValue = r.isModeUnique ? fmt(r.mode) : r.modes.map(fmt).join(', ');
    final multipleModesNote = r.isModeUnique ? '' : '<i>${t.multipleModesNote}</i><br><br>';
    buffer.write('''
<b><font color='blue'><u>${t.modeSectionTitle}</u></font></b><br><br>
${t.modeExplanationD}<br>
<font color='red'><b><u>Mo = $modeValue</u></b></font><br><br>
$multipleModesNote''');
  }

  // Shown in the first of the median/quantile sections present: the
  // "directly above" rule is the course's convention, not the only one, so
  // a user taught to average the two central values can reconcile results.
  final conventionNote = '<i>${t.quantileConventionNote}</i><br><br>';
  String tieNote(String name, double? midpoint) => midpoint == null ? '' : '<i>${t.quantileExactTieNote(name: name, value: fmt(midpoint))}</i><br><br>';

  if (selected.contains(StatOption.median)) {
    buffer.write('''
<b><font color='blue'><u>${t.medianSectionTitle}</u></font></b><br><br>
${t.medianExplanationD} <b>1/2&sum;Ni</b><br>
<font color='red'><b><u>Me = ${fmt(r.median)}</u></b></font><br><br>
${tieNote('Me', r.medianMidpoint)}$conventionNote''');
  }

  if (selected.contains(StatOption.quartiles)) {
    buffer.write('''
<b><font color='blue'><u>${t.quartilesSectionTitle}</u></font></b><br><br>
<font color='magenta'>${t.firstQuartLabel}</font><br>
${t.firstQuartExplanationD} <b>1/4&sum;Ni</b><br>
<font color='red'><b><u>Q1 = ${fmt(r.firstQuartile)}</u></b></font><br><br>
${tieNote('Q1', r.firstQuartileMidpoint)}<font color='magenta'>${t.thirdQuartLabel}</font><br>
${t.thirdQuartExplanationD} <b>3/4&sum;Ni</b><br>
<font color='red'><b><u>Q3 = ${fmt(r.thirdQuartile)}</u></b></font><br><br>
${tieNote('Q3', r.thirdQuartileMidpoint)}<font color='magenta'>${t.interQuartLabel}</font><br>
<b>IIQ = Q3 - Q1</b><br>
IIQ = ${fmt(r.thirdQuartile)} - ${fmt(r.firstQuartile)}<br>
<font color='red'><b><u>IIQ = ${fmt(r.interquartileRange)}</u></b></font><br><br>
<b><font color='blue'><u>${t.decilesSectionTitle}</u></font></b><br><br>
<font color='magenta'>${t.firstDecileLabel}</font><br>
${t.firstDecileExplanationD} <b>1/10&sum;Ni</b><br>
<font color='red'><b><u>D1 = ${fmt(r.firstDecile)}</u></b></font><br><br>
${tieNote('D1', r.firstDecileMidpoint)}<font color='magenta'>${t.ninthDecileLabel}</font><br>
${t.ninthDecileExplanationD} <b>9/10&sum;Ni</b><br>
<font color='red'><b><u>D9 = ${fmt(r.ninthDecile)}</u></b></font><br><br>
${tieNote('D9', r.ninthDecileMidpoint)}${selected.contains(StatOption.median) ? '' : conventionNote}''');
  }

  if (selected.contains(StatOption.variance)) {
    buffer.write('''
<b><font color='blue'><u>${t.varianceSectionTitle}</u></font></b><br><br>
<b>Vx&sup2; = (&sum;Xi&sup2;Ni / &sum;Ni) - X&sup2;</b><br>
Vx&sup2; = (${fmt(xi2niSum)} / ${fmt(niSum)}) - ${fmt(r.weightedMean)}&sup2;<br>
<font color='red'><b><u>Vx&sup2; = ${fmt(r.variance)}</u></b></font><br><br>
''');
  }

  if (selected.contains(StatOption.covariance)) {
    buffer.write('''
<b><font color='blue'><u>${t.covarianceSectionTitle}</u></font></b><br><br>
<i>${t.discreteCovarianceNote}</i><br><br>
<b>Cov(X,Y) = &sum;(Xi - X)(Yi - Y) / (n - 1)</b><br>
Cov(X,Y) = ${fmt(arrondi(covarianceSum, precision))} / ($n - 1)<br>
<font color='red'><b><u>Cov(X,Y) = ${fmt(r.covariance)}</u></b></font><br><br>
<b><font color='blue'><u>${t.correlationSectionTitle}</u></font></b><br><br>
<b>r = Cov(X, Y) / &sigma;(x)&sigma;(y)</b><br>
r = ${fmt(r.covariance)} / ( ${fmt(arrondi(xDeviation, precision))} * ${fmt(arrondi(yDeviation, precision))} )<br>
<font color='red'><b><u>r = ${r.isCorrelationDefined ? fmt(r.correlation) : t.undefinedValue}</u></b></font><br><br>
''');
  }

  if (selected.contains(StatOption.standardDeviation)) {
    buffer.write('''
<b><font color='blue'><u>${t.standardDeviationSectionTitle}</u></font></b><br><br>
<b>&sigma; = &radic;(Vx&sup2;)</b><br>
&sigma; = &radic;(${fmt(r.variance)})<br>
<font color='red'><b><u>&sigma; = ${fmt(r.standardDeviation)}</u></b></font><br><br>
<b><font color='blue'><u>${t.standardErrorSectionTitle}</u></font></b><br><br>
<b>s = &sigma; &times; &radic;(&sum;Ni / (&sum;Ni - 1))</b><br>
s = ${fmt(r.standardDeviation)} &times; &radic;(${fmt(niSum)} / (${fmt(niSum)} - 1))<br>
s = ${r.isStandardErrorDefined ? fmt(r.sampleStandardDeviation) : t.undefinedValue}<br><br>
<b>SE = s / &radic;&sum;Ni</b><br>
SE = ${r.isStandardErrorDefined ? fmt(r.sampleStandardDeviation) : t.undefinedValue} / &radic;${fmt(niSum)}<br>
<font color='red'><b><u>SE = ${r.isStandardErrorDefined ? fmt(r.standardError) : t.undefinedValue}</u></b></font><br><br>
''');
  }

  if (selected.contains(StatOption.coefficientOfVariation)) {
    buffer.write('''
<b><font color='blue'><u>${t.coefficientOfVariationSectionTitle}</u></font></b><br><br>
<b>CV = (Vx / X) * 100</b><br>
CV = (${fmt(r.standardDeviation)} / ${fmt(r.weightedMean)}) * 100<br>
<font color='red'><b><u>CV = ${r.isCoefficientOfVariationDefined ? fmt(r.coefficientOfVariation) : t.undefinedValue}</u></b></font><br><br>
${r.isCoefficientOfVariationDefined ? '<b>${r.isHomogeneous ? t.distribHomo : t.distribHetero}</b><br><br>' : ''}''');
  }

  buffer.write('''
<b><font color='blue'><u>${t.rangeSectionTitle}</u></font></b><br><br>
<b>E = XiMax - XiMin</b><br>
E = ${fmt(r.xi.reduce(math.max))} - ${fmt(r.xi.reduce(math.min))}<br>
<font color='red'><b><u>E = ${fmt(r.range)}</u></b></font><br><br>
''');

  return buffer.toString();
}
