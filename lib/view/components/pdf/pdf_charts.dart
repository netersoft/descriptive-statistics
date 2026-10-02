import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/services/i18n/translations.g.dart';
import '../../themes/app_theme.dart';
import '../calculators/chart_carousel.dart';

/// The PDF versions of the calculators' charts, drawn with the pdf
/// package's own chart widgets (fl_chart only renders on screen).

PdfColor get _barColor => PdfColor.fromInt(AppTheme.secondaryColor.toARGB32());

const _labelStyle = pw.TextStyle(fontSize: 8);

/// Y axis from 0 to just above the highest value, with the same steps as
/// the on-screen box plot's axis.
pw.FixedAxis<double> _valueAxis(List<double> values, String Function(double) format) {
  final max = values.fold<double>(0, (a, b) => a > b ? a : b);
  return pw.FixedAxis(axisTicks(0, max > 0 ? max : 1), format: (v) => format(v.toDouble()), textStyle: _labelStyle, divisions: true);
}

pw.FixedAxis<int> _labelAxis(List<String> labels) => pw.FixedAxis.fromStrings(labels, marginStart: 20, marginEnd: 20, ticks: true, textStyle: _labelStyle);

pw.Widget pdfBarChart({required List<String> labels, required List<double> values, required String Function(double) format}) => pw.Chart(
  grid: pw.CartesianGrid(xAxis: _labelAxis(labels), yAxis: _valueAxis(values, format)),
  datasets: [
    pw.BarDataSet(
      color: _barColor,
      width: 14,
      data: [for (var i = 0; i < values.length; i++) pw.PointChartValue(i.toDouble(), values[i])],
    ),
  ],
);

pw.Widget pdfLineChart({required List<String> labels, required List<double> values, required String Function(double) format}) => pw.Chart(
  grid: pw.CartesianGrid(xAxis: _labelAxis(labels), yAxis: _valueAxis(values, format)),
  datasets: [
    pw.LineDataSet(
      color: _barColor,
      pointSize: 2.5,
      data: [for (var i = 0; i < values.length; i++) pw.PointChartValue(i.toDouble(), values[i])],
    ),
  ],
);

/// Pie with a percentage on each slice and a legend underneath, like the
/// on-screen pie.
pw.Widget pdfPieChart({required List<String> labels, required List<double> values}) {
  final percentages = roundedPercentages(values);
  final colors = [for (final color in AppTheme.chartPalette) PdfColor.fromInt(color.toARGB32())];
  return pw.Column(
    children: [
      pw.Expanded(
        child: pw.Chart(
          grid: pw.PieGrid(),
          datasets: [
            for (var i = 0; i < values.length; i++)
              pw.PieDataSet(
                value: values[i],
                color: colors[i % colors.length],
                legend: percentages.isEmpty ? '' : '${percentages[i]}%',
                legendStyle: const pw.TextStyle(fontSize: 9, color: PdfColors.white),
                legendPosition: pw.PieLegendPosition.inside,
              ),
          ],
        ),
      ),
      pw.SizedBox(height: 6),
      pw.Wrap(
        alignment: pw.WrapAlignment.center,
        spacing: 10,
        runSpacing: 3,
        children: [
          for (var i = 0; i < labels.length; i++)
            pw.Row(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Container(width: 8, height: 8, color: colors[i % colors.length]),
                pw.SizedBox(width: 3),
                pw.Text(labels[i], style: _labelStyle),
              ],
            ),
        ],
      ),
    ],
  );
}

/// Same layout as the on-screen [BoxPlotChart]: whiskers, box and median
/// over a value axis, with the five values listed underneath.
pw.Widget pdfBoxPlot({required FiveNumberSummary summary, required String Function(double) format}) {
  final ticks = axisTicks(summary.min, summary.max);
  final low = ticks.first;
  final high = ticks.last;
  const side = 16.0;
  const axisHeight = 14.0;
  const lineColor = PdfColors.grey800;

  return pw.Column(
    children: [
      pw.Expanded(
        child: pw.LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints!.maxWidth - 2 * side;
            final height = constraints.maxHeight;
            double x(double value) => side + (high == low ? width / 2 : (value - low) / (high - low) * width);

            return pw.Stack(
              children: [
                pw.CustomPaint(
                  size: PdfPoint(constraints.maxWidth, height),
                  painter: (canvas, size) {
                    // PDF coordinates start at the bottom left.
                    const axisY = axisHeight;
                    final centerY = axisY + (size.y - axisY) / 2;
                    final boxHalf = ((size.y - axisY) * 0.25).clamp(8.0, 30.0);

                    canvas
                      ..setStrokeColor(lineColor)
                      ..setLineWidth(1)
                      ..drawLine(x(low), axisY, x(high), axisY);
                    for (final tick in ticks) {
                      canvas.drawLine(x(tick), axisY, x(tick), axisY - 3);
                    }
                    canvas
                      ..drawLine(x(summary.min), centerY, x(summary.q1), centerY)
                      ..drawLine(x(summary.q3), centerY, x(summary.max), centerY);
                    for (final end in [summary.min, summary.max]) {
                      canvas.drawLine(x(end), centerY - boxHalf / 2, x(end), centerY + boxHalf / 2);
                    }
                    canvas
                      ..strokePath()
                      ..setFillColor(PdfColor(_barColor.red, _barColor.green, _barColor.blue, 0.35).flatten())
                      ..drawRect(x(summary.q1), centerY - boxHalf, x(summary.q3) - x(summary.q1), 2 * boxHalf)
                      ..fillPath()
                      ..drawRect(x(summary.q1), centerY - boxHalf, x(summary.q3) - x(summary.q1), 2 * boxHalf)
                      ..strokePath()
                      ..setStrokeColor(_barColor)
                      ..setLineWidth(2.5)
                      ..drawLine(x(summary.median), centerY - boxHalf, x(summary.median), centerY + boxHalf)
                      ..strokePath();
                  },
                ),
                for (final tick in ticks)
                  pw.Positioned(
                    left: x(tick) - 20,
                    bottom: 0,
                    child: pw.SizedBox(
                      width: 40,
                      child: pw.Text(format(tick), style: _labelStyle, textAlign: pw.TextAlign.center),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      pw.SizedBox(height: 6),
      pw.Wrap(
        alignment: pw.WrapAlignment.center,
        spacing: 10,
        children: [
          for (final (label, value) in [
            (t.boxPlotMin, summary.min),
            ('Q1', summary.q1),
            (t.boxPlotMedian, summary.median),
            ('Q3', summary.q3),
            (t.boxPlotMax, summary.max),
          ])
            pw.Text('$label = ${format(value)}', style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    ],
  );
}
