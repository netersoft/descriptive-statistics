import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/providers/calculators/calculator_types.dart';
import '../../../core/services/i18n/translations.g.dart';
import '../../../core/stats/continuous_stats.dart';
import '../../../core/stats/rounding.dart';
import '../../../core/tools/functions/number_parsing.dart';
import '../misc/themed_html.dart';

/// Renders the step-by-step formula walkthrough for a
/// [ContinuousStatsResult], gated by which [StatOption]s are selected --
/// mirrors the legacy app's HTML "resolution" panel. Variance/covariance/
/// standard-deviation/coefficient-of-variation sections are textually
/// identical to the Discrete screen's; mode, median, quartiles and deciles
/// show the class-interpolation formula instead of a plain lookup.
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
  Widget build(BuildContext context) => ThemedHtml(buildContinuousExplanationHtml(result, l1, l2, selectedStats));
}

/// The intermediate sums below aren't part of [ContinuousStatsResult] -- it
/// only exposes final statistics -- but are cheap to recompute here from the
/// already rounded [ContinuousStatsResult.xi]/[ContinuousStatsResult.ni]
/// purely for display, reproducing exactly what the engine computed
/// internally. [l1]/[l2] must be the same (sorted) arrays the result was
/// computed from, so [ContinuousStatsResult.modalClassIndex]/
/// [ContinuousStatsResult.medianClassIndex] index into them correctly.
/// [precision] must match the value the result was computed with, so the
/// intermediate values shown here round the same way as the final stats
/// they lead into.
String buildContinuousExplanationHtml(
  ContinuousStatsResult r,
  List<double> l1,
  List<double> l2,
  Set<StatOption> selected,
) {
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

  double weightAt(int index) => index >= 0 && index < n ? r.modeWeights[index] : 0;
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
    final modeGapBefore = arrondi(r.modeWeights[r.modalClassIndex] - weightAt(r.modalClassIndex - 1), precision);
    final modeGapAfter = arrondi(r.modeWeights[r.modalClassIndex] - weightAt(r.modalClassIndex + 1), precision);
    // With unequal class widths the formula runs on densities d = Ni / k
    // instead of effectifs, so label its terms accordingly.
    final (w0, w1, w2) = r.usesDensities ? ('d0', 'd1', 'd2') : ('N0', 'N1', 'N2');
    final densitiesNote = r.usesDensities ? '<i>${t.unequalWidthsModeNote}</i><br>' : '';
    final multipleModesNote = r.isModeUnique
        ? ''
        : '<i>${t.multipleModesNote} '
              '${r.modalClassIndices.map((i) => '[${fmt(l1[i])} - ${fmt(l2[i])}[').join(', ')}'
              '</i><br><br>';
    buffer.write('''
<b><font color='blue'><u>${t.modeSectionTitle}</u></font></b><br><br>
$densitiesNote<b>Mo = L1 + k(($w0 - $w1) / (($w0 - $w1) + ($w0 - $w2)))</b><br>
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

  // Same interpolation as the median, in the class where the cumulative
  // effectif crosses the given fraction of the total.
  String interpolation(String name, String fraction, double fractionValue, int index, double value) =>
      '''
${t.quantileInterpolationLabel} <b>$fraction&sum;Ni</b><br>
<b>$name = L1 + k(($fraction * &sum;Ni - N1) / Ni)</b><br>
$name = ${fmt(l1[index])} + ${fmt(k[index])} * (((${fmt(arrondi(niSum * fractionValue, precision))}) - ${fmt(upBefore(index))}) / ${fmt(r.ni[index])})<br>
<font color='red'><b><u>$name = ${fmt(value)}</u></b></font><br><br>
''';

  if (selected.contains(StatOption.quartiles)) {
    buffer.write('''
<b><font color='blue'><u>${t.quartilesSectionTitle}</u></font></b><br><br>
<font color='magenta'>${t.firstQuartLabel}</font><br>
${interpolation('Q1', '1/4', 1 / 4, r.firstQuartileClassIndex, r.firstQuartile)}<font color='magenta'>${t.thirdQuartLabel}</font><br>
${interpolation('Q3', '3/4', 3 / 4, r.thirdQuartileClassIndex, r.thirdQuartile)}<font color='magenta'>${t.interQuartLabel}</font><br>
<b>IIQ = Q3 - Q1</b><br>
IIQ = ${fmt(r.thirdQuartile)} - ${fmt(r.firstQuartile)}<br>
<font color='red'><b><u>IIQ = ${fmt(r.interquartileRange)}</u></b></font><br><br>
<b><font color='blue'><u>${t.decilesSectionTitle}</u></font></b><br><br>
<font color='magenta'>${t.firstDecileLabel}</font><br>
${interpolation('D1', '1/10', 1 / 10, r.firstDecileClassIndex, r.firstDecile)}<font color='magenta'>${t.ninthDecileLabel}</font><br>
${interpolation('D9', '9/10', 9 / 10, r.ninthDecileClassIndex, r.ninthDecile)}''');
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
Cov(X,Y) = ${fmt(arrondi(covarianceSum, precision))} / $n - 1<br>
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
<font color='red'><b><u>CV = ${r.isCoefficientOfVariationDefined ? fmt(r.coefficientOfVariation) : t.undefinedValue}</u></b></font><br><br>
${r.isCoefficientOfVariationDefined ? '<b>${r.isHomogeneous ? t.distribHomo : t.distribHetero}</b><br><br>' : ''}''');
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
