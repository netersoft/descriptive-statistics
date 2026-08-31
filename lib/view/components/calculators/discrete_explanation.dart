import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

import '../../../core/providers/calculators/discrete_provider.dart';
import '../../../core/services/i18n/translations.g.dart';
import '../../../core/stats/discrete_stats.dart';
import '../../../core/stats/rounding.dart';

/// Renders the step-by-step formula walkthrough for a [DiscreteStatsResult],
/// gated by which [DiscreteStatOption]s are selected -- mirrors the legacy
/// app's HTML "resolution" panel, built the same way (per-checkbox HTML
/// fragments concatenated together) and rendered with the same formulas.
class DiscreteExplanation extends StatelessWidget {
  final DiscreteStatsResult result;
  final Set<DiscreteStatOption> selectedStats;

  const DiscreteExplanation({required this.result, required this.selectedStats, super.key});

  @override
  Widget build(BuildContext context) => HtmlWidget(buildDiscreteExplanationHtml(result, selectedStats), buildAsync: false);
}

/// The intermediate sums below (xiniSum, covarianceSum, the two standard
/// deviations, ...) aren't part of [DiscreteStatsResult] -- it only exposes
/// final statistics -- but are cheap to recompute here from the already
/// rounded [DiscreteStatsResult.xi]/[DiscreteStatsResult.ni] purely for
/// display, reproducing exactly what the engine computed internally.
String buildDiscreteExplanationHtml(DiscreteStatsResult r, Set<DiscreteStatOption> selected) {
  final n = r.xi.length;
  final niSum = r.ni.reduce((a, b) => a + b);
  final xiniSum = r.xini.reduce((a, b) => a + b);
  final xi2niSum = r.xi2ni.reduce((a, b) => a + b);

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

  if (selected.contains(DiscreteStatOption.mean)) {
    buffer.write('''
<b><font color='blue'><u>${t.meanSectionTitle}</u></font></b><br>
<font color='magenta'>${t.weightedMeanLabel}</font><br>
<b>X = &sum;XiNi / &sum;Ni</b><br>
X = ${noZero(xiniSum)} / ${noZero(niSum)}<br>
<font color='red'><b><u>X = ${noZero(r.weightedMean)}</u></b></font><br><br>
<font color='magenta'>${t.simpleMeanLabel}</font><br>
<b>X = &sum;Ni / n</b><br>
X = ${noZero(niSum)} / $n<br>
<font color='red'><b><u>X = ${noZero(r.simpleMean)}</u></b></font><br><br>
''');
  }

  if (selected.contains(DiscreteStatOption.mode)) {
    buffer.write('''
<b><font color='blue'><u>${t.modeSectionTitle}</u></font></b><br><br>
${t.modeExplanationD}<br>
<font color='red'><b><u>Mo = ${noZero(r.mode)}</u></b></font><br><br>
''');
  }

  if (selected.contains(DiscreteStatOption.median)) {
    buffer.write('''
<b><font color='blue'><u>${t.medianSectionTitle}</u></font></b><br><br>
${t.medianExplanationD} <b>1/2&sum;Ni</b><br>
<font color='red'><b><u>Me = ${noZero(r.median)}</u></b></font><br><br>
''');
  }

  if (selected.contains(DiscreteStatOption.quartiles)) {
    buffer.write('''
<b><font color='blue'><u>${t.quartilesSectionTitle}</u></font></b><br><br>
<font color='magenta'>${t.firstQuartLabel}</font><br>
${t.firstQuartExplanationD} <b>1/4&sum;Ni</b><br>
<font color='red'><b><u>Q1 = ${noZero(r.firstQuartile)}</u></b></font><br><br>
<font color='magenta'>${t.thirdQuartLabel}</font><br>
${t.thirdQuartExplanationD} <b>3/4&sum;Ni</b><br>
<font color='red'><b><u>Q3 = ${noZero(r.thirdQuartile)}</u></b></font><br><br>
<font color='magenta'>${t.interQuartLabel}</font><br>
<b>IIQ = Q3 - Q1</b><br>
IIQ = ${noZero(r.thirdQuartile)} - ${noZero(r.firstQuartile)}<br>
<font color='red'><b><u>IIQ = ${noZero(r.interquartileRange)}</u></b></font><br><br>
<b><font color='blue'><u>${t.decilesSectionTitle}</u></font></b><br><br>
<font color='magenta'>${t.firstDecileLabel}</font><br>
${t.firstDecileExplanationD} <b>1/10&sum;Ni</b><br>
<font color='red'><b><u>Q1 = ${noZero(r.firstDecile)}</u></b></font><br><br>
<font color='magenta'>${t.ninthDecileLabel}</font><br>
${t.ninthDecileExplanationD} <b>9/10&sum;Ni</b><br>
<font color='red'><b><u>Q3 = ${noZero(r.ninthDecile)}</u></b></font><br><br>
''');
  }

  if (selected.contains(DiscreteStatOption.variance)) {
    buffer.write('''
<b><font color='blue'><u>${t.varianceSectionTitle}</u></font></b><br><br>
<b>Vx&sup2; = (&sum;Xi&sup2;Ni / &sum;Ni) - X&sup2;</b><br>
Vx&sup2; = (${noZero(xi2niSum)} / ${noZero(niSum)}) - ${noZero(r.weightedMean)}&sup2;<br>
<font color='red'><b><u>Vx&sup2; = ${noZero(r.variance)}</u></b></font><br><br>
''');
  }

  if (selected.contains(DiscreteStatOption.covariance)) {
    buffer.write('''
<b><font color='blue'><u>${t.covarianceSectionTitle}</u></font></b><br><br>
<b>Cov(X,Y) = &sum;(Xi - X)(Yi - Y) / (n - 1)</b><br>
Cov(X,Y) = ${noZero(arrondi(covarianceSum, 3))} / $n - 1<br>
<font color='red'><b><u>Cov(X,Y) = ${noZero(r.covariance)}</u></b></font><br><br>
<b><font color='blue'><u>${t.correlationSectionTitle}</u></font></b><br><br>
<b>r = Cov(X, Y) / &sigma;(x)&sigma;(y)</b><br>
r = ${noZero(r.covariance)} / ( ${noZero(arrondi(xDeviation, 3))} * ${noZero(arrondi(yDeviation, 3))} )<br>
<font color='red'><b><u>r = ${noZero(r.correlation)}</u></b></font><br><br>
''');
  }

  if (selected.contains(DiscreteStatOption.standardDeviation)) {
    buffer.write('''
<b><font color='blue'><u>${t.standardDeviationSectionTitle}</u></font></b><br><br>
<b>&sigma; = &radic;(Vx&sup2;)</b><br>
&sigma; = &radic;(${noZero(r.variance)})<br>
<font color='red'><b><u>&sigma; = ${noZero(r.standardDeviation)}</u></b></font><br><br>
<b><font color='blue'><u>${t.standardErrorSectionTitle}</u></font></b><br><br>
<b>SE = &sigma; / &radic;n</b><br>
SE = ${noZero(r.standardDeviation)} / &radic;$n<br>
<font color='red'><b><u>SE = ${noZero(r.standardError)}</u></b></font><br><br>
''');
  }

  if (selected.contains(DiscreteStatOption.coefficientOfVariation)) {
    buffer.write('''
<b><font color='blue'><u>${t.coefficientOfVariationSectionTitle}</u></font></b><br><br>
<b>CV = (Vx / X) * 100</b><br>
CV = (${noZero(r.standardDeviation)} / ${noZero(r.weightedMean)}) * 100<br>
<font color='red'><b><u>CV = ${noZero(r.coefficientOfVariation)}</u></b></font><br><br>
<b>${r.isHomogeneous ? t.distribHomo : t.distribHetero}</b><br><br>
''');
  }

  buffer.write('''
<b><font color='blue'><u>${t.rangeSectionTitle}</u></font></b><br><br>
<b>E = XiMax - XiMin</b><br>
E = ${noZero(r.xi.reduce(math.max))} - ${noZero(r.xi.reduce(math.min))}<br>
<font color='red'><b><u>E = ${noZero(r.range)}</u></b></font><br><br>
''');

  return buffer.toString();
}
