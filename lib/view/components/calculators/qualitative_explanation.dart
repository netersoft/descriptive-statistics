import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

import '../../../core/providers/calculators/calculator_types.dart';
import '../../../core/services/i18n/translations.g.dart';
import '../../../core/stats/qualitative_stats.dart';
import '../../../core/stats/rounding.dart';
import '../../../core/tools/functions/number_parsing.dart';

/// Renders the legend, total effectif, and (gated by [selectedStats]) mean
/// and mode sections for a [QualitativeStatsResult] -- mirrors the legacy
/// app's HTML "resolution" panel. Nominal data has no median, quartiles,
/// variance, etc., so this is a much smaller panel than the Discrete/
/// Continuous screens'.
class QualitativeExplanation extends StatelessWidget {
  final QualitativeStatsResult result;
  final Set<QualitativeStatOption> selectedStats;

  const QualitativeExplanation({required this.result, required this.selectedStats, super.key});

  @override
  Widget build(BuildContext context) => HtmlWidget(buildQualitativeExplanationHtml(result, selectedStats), buildAsync: false);
}

String buildQualitativeExplanationHtml(QualitativeStatsResult r, Set<QualitativeStatOption> selected) {
  final sep = decimalSeparatorForLocale(LocaleSettings.currentLocale.languageCode);
  String fmt(double v) => noZero(v, decimalSeparator: sep);

  final buffer = StringBuffer('''
<b>${t.qltTabTitle1}</b> : ${t.tableModalities}<br>
<b>${t.qltTabTitle2}</b> : ${t.tableEffectifs}<br>
<b>${t.qltTabTitle3}</b> : ${t.tableFrequencies}<br>
<b>${t.qltTabTitle4}</b> : ${t.tableCEffectifs}<br>
<b>${t.qltTabTitle5}</b> : ${t.tableCFrequencies}<br><br>
<b><font color='blue'><u>${t.effectifTotal}</u></font></b><br><br>
<b>E = &sum;Ni</b><br>
<font color='red'><b><u>E = ${fmt(r.total)}</u></b></font><br><br>
''');

  if (selected.contains(QualitativeStatOption.mean)) {
    buffer.write('''
<b><font color='blue'><u>${t.meanSectionTitle}</u></font></b><br><br>
<b>X = &sum;Ni / n</b><br>
X = ${fmt(r.total)} / ${r.modalities.length}<br>
<font color='red'><b><u>X = ${fmt(r.mean)}</u></b></font><br><br>
''');
  }

  if (selected.contains(QualitativeStatOption.mode)) {
    final modeValue = r.isModeUnique ? r.modeModality : r.modeModalities.join(', ');
    final multipleModesNote = r.isModeUnique ? '' : '<i>${t.multipleModesNote}</i><br><br>';
    buffer.write('''
<b><font color='blue'><u>${t.modeSectionTitle}</u></font></b><br><br>
${t.qltMode}<br>
<font color='red'><b><u>Mo >>> $modeValue</u></b></font><br><br>
$multipleModesNote''');
  }

  return buffer.toString();
}
