import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/data/backups/backup_data.dart';
import '../../../core/providers/calculators/calculator_types.dart';
import '../../../core/providers/settings/settings_provider.dart';
import '../../../core/services/i18n/translations.g.dart';
import '../../../core/stats/continuous_stats.dart';
import '../../../core/stats/discrete_stats.dart';
import '../../../core/stats/qualitative_stats.dart';
import '../../../core/stats/rounding.dart';
import '../../../core/stats/stats_exceptions.dart';
import '../../../core/tools/constants/chart_options.dart';
import '../../../core/tools/functions/number_parsing.dart';
import '../calculators/chart_carousel.dart';
import '../calculators/continuous_explanation.dart';
import '../calculators/discrete_explanation.dart';
import '../calculators/qualitative_explanation.dart';
import '../calculators/share_text.dart';
import 'legacy_html.dart';
import 'pdf_charts.dart';

/// The chart types selected in Settings, per calculator.
typedef PdfChartTypes = ({
  Set<QuantitativeChartType> discrete,
  Set<QuantitativeChartType> continuous,
  Set<QualitativeChartType> qualitative,
});

PdfChartTypes pdfChartTypes(SettingsState settings) => (
  discrete: settings.discreteChartTypes,
  continuous: settings.continuousChartTypes,
  qualitative: settings.qualitativeChartTypes,
);

/// What a calculation's PDF shows besides its explanation.
typedef _Report = ({
  String kindTitle,
  List<String> headers,
  List<List<String>> rows,
  List<String> results,
  List<(String, pw.Widget)> charts,
  String? chartNote,
  String explanationHtml,
});

/// Builds the PDF of a calculation: its frequency table, the selected
/// results, the charts selected in Settings, then the step-by-step
/// explanation. Everything is recomputed from [data], like the Backups
/// screen does, so it's in the app's current language. Backups saved
/// before 1.6 have no data: only their stored [fallbackHtml] explanation
/// is shown.
Future<Uint8List> buildCalculationPdf({
  required String title,
  required String dateLabel,
  required BackupData? data,
  required String fallbackHtml,
  required PdfChartTypes chartTypes,
}) async {
  final theme = await _loadTheme();
  final report = data == null ? null : _report(data, chartTypes);
  final explanation = report?.explanationHtml ?? fallbackHtml;

  final document = pw.Document(title: title, creator: t.appNameAlt)
    ..addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(t.appNameAlt, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            pw.Text(
              t.pdfPage(page: context.pageNumber, total: context.pagesCount),
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ],
        ),
        build: (context) => [
          pw.Text(title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(
            [?report?.kindTitle, dateLabel].join(' · '),
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.Divider(color: PdfColors.grey400),
          if (report != null) ...[
            _heading(t.statsTable),
            pw.TableHelper.fromTextArray(
              headers: report.headers,
              data: report.rows,
              cellAlignment: pw.Alignment.center,
              headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.5),
            ),
            if (report.results.isNotEmpty) ...[
              _heading(t.pdfResultsTitle),
              for (final line in report.results) pw.Bullet(text: line, style: const pw.TextStyle(fontSize: 10)),
            ],
            if (report.charts.isNotEmpty) ...[
              _heading(t.pdfChartsTitle),
              for (final (label, chart) in report.charts)
                // Keeps a chart's title on the same page as the chart.
                pw.Inseparable(
                  child: pw.Column(
                    children: [
                      pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 6),
                      pw.SizedBox(height: 180, child: chart),
                      pw.SizedBox(height: 14),
                    ],
                  ),
                ),
              if (report.chartNote != null) pw.Text(report.chartNote!, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
            ],
          ],
          ..._withHeading(t.pdfExplanationTitle, explanationWidgets(explanation)),
        ],
      ),
    );

  return document.save();
}

pw.Widget _heading(String text) => pw.Padding(
  padding: const pw.EdgeInsets.only(top: 14, bottom: 8),
  child: pw.Text(
    text,
    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
  ),
);

/// [heading] then [content], with the heading kept on the same page as
/// the first few lines under it.
List<pw.Widget> _withHeading(String heading, List<pw.Widget> content) {
  const keptLines = 3;
  return [
    pw.Inseparable(
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [_heading(heading), ...content.take(keptLines)]),
    ),
    ...content.skip(keptLines),
  ];
}

/// The explanation HTML as one text widget per line, so a page break can
/// fall between any two lines. Blank lines become a small gap.
List<pw.Widget> explanationWidgets(String html) => [
  for (final line in parseLegacyHtml(html))
    if (line.isEmpty)
      pw.SizedBox(height: 6)
    else
      pw.RichText(
        text: pw.TextSpan(
          style: const pw.TextStyle(fontSize: 10),
          children: [
            for (final run in line)
              pw.TextSpan(
                text: run.text,
                style: pw.TextStyle(
                  fontWeight: run.bold ? pw.FontWeight.bold : null,
                  fontStyle: run.italic ? pw.FontStyle.italic : null,
                  decoration: run.underline ? pw.TextDecoration.underline : null,
                  color: _pdfColor(run.color),
                ),
              ),
          ],
        ),
      ),
];

/// The explanation's `<font color>` names, darkened a little where the
/// pure color is hard to read on paper.
const _namedColors = {
  'blue': PdfColors.blue800,
  'red': PdfColors.red700,
  'magenta': PdfColor.fromInt(0xFFC2185B),
  'green': PdfColors.green700,
  'black': PdfColors.black,
};

PdfColor? _pdfColor(String? color) {
  if (color == null) return null;
  if (color.startsWith('#') && color.length == 7) {
    final value = int.tryParse(color.substring(1), radix: 16);
    if (value != null) return PdfColor.fromInt(0xFF000000 | value);
  }
  return _namedColors[color.toLowerCase()];
}

_Report? _report(BackupData data, PdfChartTypes chartTypes) {
  final sep = decimalSeparatorForLocale(LocaleSettings.currentLocale.languageCode);
  String fmt(double v) => noZero(v, decimalSeparator: sep);
  final quantitativeHeaders = [t.tableXi, t.tableNi, t.tableXini, t.tableXi2ni, t.tableUp, t.tableDown];

  try {
    switch (data.kind) {
      case BackupKind.discrete:
        final r = computeDiscreteStats(data.numbers(0), data.numbers(1), precision: data.precision);
        final selected = {for (final name in data.selectedStats) StatOption.values.byName(name)};
        return (
          kindTitle: t.discreteChartTypesTitle,
          headers: quantitativeHeaders,
          rows: [
            for (var i = 0; i < r.xi.length; i++)
              [r.xi[i], r.ni[i], r.xini[i], r.xi2ni[i], r.cumulativeAscending[i], r.cumulativeDescending[i]].map(fmt).toList(),
          ],
          results: discreteResultLines(r, selected),
          charts: selected.contains(StatOption.charts)
              ? _quantitativeCharts(
                  labels: r.xi.map(fmt).toList(),
                  values: r.ni,
                  summary: (min: r.minimum, q1: r.firstQuartile, median: r.median, q3: r.thirdQuartile, max: r.maximum),
                  types: chartTypes.discrete,
                  format: fmt,
                )
              : const [],
          chartNote: null,
          explanationHtml: buildDiscreteExplanationHtml(r, selected),
        );

      case BackupKind.continuous:
        final l1 = data.numbers(0);
        // The engine reads the bounds as typed (it reports whether it closed
        // gaps); the class labels show the bounds it computed with.
        final r = computeContinuousStats(l1, data.numbers(1), data.numbers(2), precision: data.precision);
        final l2 = closeClassGaps(l1, data.numbers(1));
        final selected = {for (final name in data.selectedStats) StatOption.values.byName(name)};
        final showCharts = selected.contains(StatOption.charts) && chartTypes.continuous.isNotEmpty;
        return (
          kindTitle: t.continuousChartTypesTitle,
          // The screen only shows the midpoints; on paper, the classes
          // they come from are worth having next to them.
          headers: [t.pdfClassesColumn, ...quantitativeHeaders],
          rows: [
            for (var i = 0; i < r.xi.length; i++)
              [
                '[${fmt(l1[i])} ; ${fmt(l2[i])}[',
                ...[r.xi[i], r.ni[i], r.xini[i], r.xi2ni[i], r.cumulativeAscending[i], r.cumulativeDescending[i]].map(fmt),
              ],
          ],
          results: continuousResultLines(r, selected),
          charts: showCharts
              ? _quantitativeCharts(
                  labels: r.xi.map(fmt).toList(),
                  // Densities with unequal class widths, like on screen.
                  values: r.usesDensities ? r.modeWeights : r.ni,
                  summary: (min: r.minimum, q1: r.firstQuartile, median: r.median, q3: r.thirdQuartile, max: r.maximum),
                  types: chartTypes.continuous,
                  format: fmt,
                )
              : const [],
          chartNote: showCharts && r.usesDensities ? t.densityChartNote : null,
          explanationHtml: buildContinuousExplanationHtml(r, l1, l2, selected),
        );

      case BackupKind.qualitative:
        final r = computeQualitativeStats(data.strings(0), data.numbers(1), precision: data.precision);
        final selected = {for (final name in data.selectedStats) QualitativeStatOption.values.byName(name)};
        return (
          kindTitle: t.qualitativeChartTypesTitle,
          headers: [t.qltTabTitle1, t.qltTabTitle2, t.qltTabTitle3, t.qltTabTitle4, t.qltTabTitle5],
          rows: [
            for (var i = 0; i < r.modalities.length; i++)
              [
                r.modalities[i],
                ...[r.effectifs[i], r.frequencies[i], r.cumulativeEffectifs[i], r.cumulativeFrequencies[i]].map(fmt),
              ],
          ],
          results: qualitativeResultLines(r, selected),
          charts: selected.contains(QualitativeStatOption.charts)
              ? [
                  if (chartTypes.qualitative.contains(QualitativeChartType.bar))
                    (t.chartTypeBar, pdfBarChart(labels: r.modalities, values: r.effectifs, format: fmt)),
                  if (chartTypes.qualitative.contains(QualitativeChartType.pie)) (t.chartTypePie, pdfPieChart(labels: r.modalities, values: r.effectifs)),
                ]
              : const [],
          chartNote: null,
          explanationHtml: buildQualitativeExplanationHtml(r, selected),
        );
    }
  } on StatsInputException {
    return null;
  }
}

List<(String, pw.Widget)> _quantitativeCharts({
  required List<String> labels,
  required List<double> values,
  required FiveNumberSummary summary,
  required Set<QuantitativeChartType> types,
  required String Function(double) format,
}) => [
  if (types.contains(QuantitativeChartType.bar)) (t.chartTypeBar, pdfBarChart(labels: labels, values: values, format: format)),
  if (types.contains(QuantitativeChartType.line)) (t.chartTypeLine, pdfLineChart(labels: labels, values: values, format: format)),
  if (types.contains(QuantitativeChartType.boxPlot)) (t.chartTypeBoxPlot, pdfBoxPlot(summary: summary, format: format)),
];

/// Montserrat, the app's font, which has no Greek letters: the σ of the
/// standard deviation comes from a Noto Sans subset (assets/fonts/
/// noto_sans_greek, Greek block only) used as a fallback.
Future<pw.ThemeData> _loadTheme() async {
  Future<pw.Font> font(String path) async => pw.Font.ttf(await rootBundle.load(path));

  final bold = await font('assets/fonts/montserrat/montserrat_bold.ttf');
  return pw.ThemeData.withFont(
    base: await font('assets/fonts/montserrat/montserrat_regular.ttf'),
    bold: bold,
    italic: await font('assets/fonts/montserrat/montserrat_italic.ttf'),
    // No bold italic in the app's fonts; the explanations never combine
    // the two anyway.
    boldItalic: bold,
    // The first fallback font with the glyph wins, so a bold σ is drawn
    // regular: not worth bundling a bold subset for.
    fontFallback: [await font('assets/fonts/noto_sans_greek/noto_sans_greek_regular.ttf')],
  );
}
