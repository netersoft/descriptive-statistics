import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

import '../../../core/providers/calculators/calculator_types.dart';
import '../../../core/services/i18n/translations.g.dart';
import '../../../core/stats/continuous_stats.dart';
import '../../../core/stats/rounding.dart';
import '../../../core/tools/functions/number_parsing.dart';

/// Renders the step-by-step formula walkthrough for a
/// [ContinuousStatsResult], gated by which [StatOption]s are selected --
/// mirrors the legacy app's HTML "resolution" panel. Quartiles/deciles/
/// variance/covariance/standard-deviation/coefficient-of-variation sections
/// are textually identical to the Discrete screen's (only the underlying
/// values differ, since they're interpolated here); mode and median show
/// the class-interpolation formula instead of a plain lookup.
class ContinuousExplanation extends StatelessWidget {
  final ContinuousStatsResult result;
  final List<double> l1;
  final List<double> l2;
  final Set<StatOption> selectedStats;

  const ContinuousExplanation({
    required this.result,
    required this.l1,
    required this.l2,
    required this.selectedStats,
    super.key,
  });

  @override
  Widget build(BuildContext context) => HtmlWidget(buildContinuousExplanationHtml(result, l1, l2, selectedStats), buildAsync: false);
}

/// The intermediate sums below aren't part of [ContinuousStatsResult] -- it
/// only exposes final statistics -- but are cheap to recompute here from the
/// already rounded [ContinuousStatsResult.xi]/[ContinuousStatsResult.ni]
/// purely for display, reproducing exactly what the engine computed
/// internally.
String buildContinuousExplanationHtml(
  ContinuousStatsResult r,
  List<double> l1,
  List<double> l2,
  Set<StatOption> selected,
) {
  final sep = decimalSeparatorForLocale(LocaleSettings.currentLocale.languageCode);
  String fmt(double v) => noZero(v, decimalSeparator: sep);

  final n = r.xi.length;
  final niSum = r.ni.reduce((a, b) => a + b);
  final xiniSum = r.xini.reduce((a, b) => a + b);
  final xi2niSum = r.xi2ni.reduce((a, b) => a + b);
  final k = List<double>.generate(n, (i) => l2[i] - l1[i]);

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

  double niAt(int index) => index >= 0 && index < n ? r.ni[index] : 0;
  double upBefore(int index) => index > 0 ? r.cumulativeAscending[index - 1] : 0;

  final buffer = StringBuffer('''
${t.modalClassLabel}${fmt(l1[r.modalClassIndex])} - ${fmt(l2[r.modalClassIndex])}[<br>
${t.medianClassLabel}${fmt(l1[r.medianClassIndex])} - ${fmt(l2[r.medianClassIndex])}[<br><br>
''');

  if (selected.contains(StatOption.mean)) {
    buffer.write('''
<b><font color='blue'><u>${t.meanSectionTitle}</u></font></b><br>
<font color='magenta'>${t.weightedMeanLabel}</font><br>
<b>X = &sum;XiNi / &sum;Ni</b><br>
X = ${fmt(xiniSum)} / ${fmt(niSum)}<br>
<font color='red'><b><u>X = ${fmt(r.weightedMean)}</u></b></font><br><br>
<font color='magenta'>${t.simpleMeanLabel}</font><br>
<b>X = &sum;Ni / n</b><br>
X = ${fmt(niSum)} / $n<br>
<font color='red'><b><u>X = ${fmt(r.simpleMean)}</u></b></font><br><br>
''');
  }

  if (selected.contains(StatOption.mode)) {
    final modeGapBefore = r.ni[r.modalClassIndex] - niAt(r.modalClassIndex - 1);
    final modeGapAfter = r.ni[r.modalClassIndex] - niAt(r.modalClassIndex + 1);
    final multipleModesNote = r.isModeUnique
        ? ''
        : '<i>${t.multipleModesNote} '
              '${r.modalClassIndices.map((i) => '[${fmt(l1[i])} - ${fmt(l2[i])}[').join(', ')}'
              '</i><br><br>';
    buffer.write('''
<b><font color='blue'><u>${t.modeSectionTitle}</u></font></b><br><br>
<b>Mo = L1 + k((N0 - N1) / ((N0 - N1) + (N0 - N2))</b><br>
Mo = ${fmt(l1[r.modalClassIndex])} + ${fmt(k[r.modalClassIndex])} * ((${fmt(modeGapBefore)}) / ((${fmt(modeGapBefore)})+(${fmt(modeGapAfter)})))<br>
<font color='red'><b><u>Mo = ${fmt(r.mode)}</u></b></font><br><br>
$multipleModesNote''');
  }

  if (selected.contains(StatOption.median)) {
    buffer.write('''
<b><font color='blue'><u>${t.medianSectionTitle}</u></font></b><br><br>
<b>Me = L1 + k((1/2 * &sum;Ni - N1) / Ne)</b><br>
Me = ${fmt(l1[r.medianClassIndex])} + ${fmt(k[r.medianClassIndex])} * (((${fmt(niSum / 2)}) - ${fmt(upBefore(r.medianClassIndex))}) / ${fmt(r.ni[r.medianClassIndex])})<br>
<font color='red'><b><u>Me = ${fmt(r.median)}</u></b></font><br><br>
''');
  }

  if (selected.contains(StatOption.quartiles)) {
    buffer.write('''
<b><font color='blue'><u>${t.quartilesSectionTitle}</u></font></b><br><br>
<font color='magenta'>${t.firstQuartLabel}</font><br>
${t.firstQuartExplanationD} <b>1/4&sum;Ni</b><br>
<font color='red'><b><u>Q1 = ${fmt(r.firstQuartile)}</u></b></font><br><br>
<font color='magenta'>${t.thirdQuartLabel}</font><br>
${t.thirdQuartExplanationD} <b>3/4&sum;Ni</b><br>
<font color='red'><b><u>Q3 = ${fmt(r.thirdQuartile)}</u></b></font><br><br>
<font color='magenta'>${t.interQuartLabel}</font><br>
<b>IIQ = Q3 - Q1</b><br>
IIQ = ${fmt(r.thirdQuartile)} - ${fmt(r.firstQuartile)}<br>
<font color='red'><b><u>IIQ = ${fmt(r.interquartileRange)}</u></b></font><br><br>
<b><font color='blue'><u>${t.decilesSectionTitle}</u></font></b><br><br>
<font color='magenta'>${t.firstDecileLabel}</font><br>
${t.firstDecileExplanationD} <b>1/10&sum;Ni</b><br>
<font color='red'><b><u>Q1 = ${fmt(r.firstDecile)}</u></b></font><br><br>
<font color='magenta'>${t.ninthDecileLabel}</font><br>
${t.ninthDecileExplanationD} <b>9/10&sum;Ni</b><br>
<font color='red'><b><u>Q3 = ${fmt(r.ninthDecile)}</u></b></font><br><br>
''');
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
<b>Cov(X,Y) = &sum;(Xi - X)(Yi - Y) / (n - 1)</b><br>
Cov(X,Y) = ${fmt(arrondi(covarianceSum, 3))} / $n - 1<br>
<font color='red'><b><u>Cov(X,Y) = ${fmt(r.covariance)}</u></b></font><br><br>
<b><font color='blue'><u>${t.correlationSectionTitle}</u></font></b><br><br>
<b>r = Cov(X, Y) / &sigma;(x)&sigma;(y)</b><br>
r = ${fmt(r.covariance)} / ( ${fmt(arrondi(xDeviation, 3))} * ${fmt(arrondi(yDeviation, 3))} )<br>
<font color='red'><b><u>r = ${fmt(r.correlation)}</u></b></font><br><br>
''');
  }

  if (selected.contains(StatOption.standardDeviation)) {
    buffer.write('''
<b><font color='blue'><u>${t.standardDeviationSectionTitle}</u></font></b><br><br>
<b>&sigma; = &radic;(Vx&sup2;)</b><br>
&sigma; = &radic;(${fmt(r.variance)})<br>
<font color='red'><b><u>&sigma; = ${fmt(r.standardDeviation)}</u></b></font><br><br>
<b><font color='blue'><u>${t.standardErrorSectionTitle}</u></font></b><br><br>
<b>SE = &sigma; / &radic;n</b><br>
SE = ${fmt(r.standardDeviation)} / &radic;$n<br>
<font color='red'><b><u>SE = ${fmt(r.standardError)}</u></b></font><br><br>
''');
  }

  if (selected.contains(StatOption.coefficientOfVariation)) {
    buffer.write('''
<b><font color='blue'><u>${t.coefficientOfVariationSectionTitle}</u></font></b><br><br>
<b>CV = (Vx / X) * 100</b><br>
CV = (${fmt(r.standardDeviation)} / ${fmt(r.weightedMean)}) * 100<br>
<font color='red'><b><u>CV = ${fmt(r.coefficientOfVariation)}</u></b></font><br><br>
<b>${r.isHomogeneous ? t.distribHomo : t.distribHetero}</b><br><br>
''');
  }

  // Unlike the discrete screen, the range is between the class bounds
  // (max of L2, min of L1), not the class midpoints.
  buffer.write('''
<b><font color='blue'><u>${t.rangeSectionTitle}</u></font></b><br><br>
<b>E = XiMax - XiMin</b><br>
E = ${fmt(l2.reduce(math.max))} - ${fmt(l1.reduce(math.min))}<br>
<font color='red'><b><u>E = ${fmt(r.range)}</u></b></font><br><br>
''');

  return buffer.toString();
}
