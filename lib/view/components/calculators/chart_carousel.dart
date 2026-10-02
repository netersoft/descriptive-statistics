import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/services/i18n/translations.g.dart';
import '../../../core/stats/rounding.dart';
import '../../../core/tools/constants/chart_options.dart';
import '../../../core/tools/functions/number_parsing.dart';
import '../../themes/app_theme.dart';

/// Paged view over a fixed list of charts, with a page indicator and
/// next/prev arrows -- one page per chart type selected in Settings for
/// this calculator, mirrors the legacy app's `switchingDefault` chart
/// pager.
class ChartCarousel extends StatefulWidget {
  final List<Widget> charts;

  const ChartCarousel({required this.charts, super.key});

  @override
  State<ChartCarousel> createState() => _ChartCarouselState();
}

class _ChartCarouselState extends State<ChartCarousel> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    _controller.animateToPage(page, duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.charts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          context.t.noChartTypeSelected,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 260,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: context.t.previous,
                onPressed: _page > 0 ? () => _goTo(_page - 1) : null,
              ),
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (page) => setState(() => _page = page),
                  children: [for (final chart in widget.charts) Padding(padding: const EdgeInsets.all(8), child: chart)],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: context.t.next,
                onPressed: _page < widget.charts.length - 1 ? () => _goTo(_page + 1) : null,
              ),
            ],
          ),
        ),
        if (widget.charts.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.charts.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: CircleAvatar(
                    radius: 3,
                    backgroundColor: i == _page ? Theme.of(context).colorScheme.primary : Colors.grey.shade400,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// The five values a box plot is drawn from.
typedef FiveNumberSummary = ({double min, double q1, double median, double q3, double max});

/// Builds one chart widget per selected [QuantitativeChartType], from a
/// discrete/continuous result's `xi`/`ni` arrays and its [summary] for the
/// box plot -- shared by the Discrete and Continuous screens.
List<Widget> buildQuantitativeCharts({
  required List<double> xi,
  required List<double> ni,
  required FiveNumberSummary summary,
  required Set<QuantitativeChartType> types,
}) => [
  if (types.contains(QuantitativeChartType.bar)) _quantitativeBarChart(xi: xi, ni: ni),
  if (types.contains(QuantitativeChartType.line)) _quantitativeLineChart(xi: xi, ni: ni),
  if (types.contains(QuantitativeChartType.boxPlot)) BoxPlotChart(summary: summary),
];

/// Builds one chart widget per selected [QualitativeChartType], from a
/// qualitative result's aggregated modalities/effectifs.
List<Widget> buildQualitativeCharts({
  required List<String> modalities,
  required List<double> effectifs,
  required Set<QualitativeChartType> types,
}) => [
  if (types.contains(QualitativeChartType.bar)) qualitativeBarChart(labels: modalities, values: effectifs),
  if (types.contains(QualitativeChartType.pie)) _qualitativePieChart(labels: modalities, values: effectifs),
];

Widget _bottomLabel(List<String> labels, double value, TitleMeta meta) {
  final index = value.toInt();
  if (index < 0 || index >= labels.length) return const SizedBox.shrink();
  return SideTitleWidget(
    meta: meta,
    space: 6,
    child: Text(labels[index], style: const TextStyle(fontSize: 11)),
  );
}

/// Simple bar chart of arbitrary (label, value) pairs -- also used for the
/// Backups screen's mini-chart, which only ever needs one plain view of
/// the saved xi/ni.
Widget qualitativeBarChart({required List<String> labels, required List<double> values}) => Builder(
  builder: (context) => BarChart(
    BarChartData(
      barTouchData: const BarTouchData(enabled: false),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) => _bottomLabel(labels, v, m), reservedSize: 28)),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
        topTitles: const AxisTitles(),
        rightTitles: const AxisTitles(),
      ),
      borderData: FlBorderData(show: false),
      barGroups: [
        for (var i = 0; i < values.length; i++)
          BarChartGroupData(
            x: i,
            barRods: [BarChartRodData(toY: values[i], color: Theme.of(context).colorScheme.primary, width: 16)],
          ),
      ],
    ),
  ),
);

String _fmt(double v) => noZero(v, decimalSeparator: decimalSeparatorForLocale(LocaleSettings.currentLocale.languageCode));

Widget _quantitativeBarChart({required List<double> xi, required List<double> ni}) => qualitativeBarChart(labels: xi.map(_fmt).toList(), values: ni);

Widget _quantitativeLineChart({required List<double> xi, required List<double> ni}) {
  final labels = xi.map(_fmt).toList();
  return Builder(
    builder: (context) => LineChart(
      LineChartData(
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, interval: 1, getTitlesWidget: (v, m) => _bottomLabel(labels, v, m), reservedSize: 28),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [for (var i = 0; i < ni.length; i++) FlSpot(i.toDouble(), ni[i])],
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    ),
  );
}

/// Horizontal box plot: whiskers from the minimum to the maximum, a box
/// from Q1 to Q3 split at the median, over a value axis. fl_chart has no
/// box plot, so it is painted directly. The five values are listed under
/// it, since their labels would overlap on the axis when values are close.
class BoxPlotChart extends StatelessWidget {
  final FiveNumberSummary summary;

  const BoxPlotChart({required this.summary, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labels = [
      (context.t.boxPlotMin, summary.min),
      ('Q1', summary.q1),
      (context.t.boxPlotMedian, summary.median),
      ('Q3', summary.q3),
      (context.t.boxPlotMax, summary.max),
    ];
    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            size: Size.infinite,
            painter: _BoxPlotPainter(
              summary: summary,
              boxColor: theme.colorScheme.primary,
              lineColor: theme.colorScheme.onSurface,
              labelStyle: theme.textTheme.bodySmall!.copyWith(fontSize: 11),
              format: _fmt,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 4,
          children: [
            for (final (label, value) in labels) Text('$label = ${_fmt(value)}', style: const TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }
}

class _BoxPlotPainter extends CustomPainter {
  final FiveNumberSummary summary;
  final Color boxColor;
  final Color lineColor;
  final TextStyle labelStyle;
  final String Function(double) format;

  _BoxPlotPainter({required this.summary, required this.boxColor, required this.lineColor, required this.labelStyle, required this.format});

  static const _sidePadding = 16.0;
  static const _axisHeight = 24.0;

  @override
  void paint(Canvas canvas, Size size) {
    final ticks = axisTicks(summary.min, summary.max);
    final low = ticks.first;
    final high = ticks.last;
    final width = size.width - 2 * _sidePadding;
    double x(double value) => _sidePadding + (high == low ? width / 2 : (value - low) / (high - low) * width);

    final line = Paint()
      ..color = lineColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Value axis with its ticks.
    final axisY = size.height - _axisHeight;
    canvas.drawLine(Offset(x(low), axisY), Offset(x(high), axisY), line);
    for (final tick in ticks) {
      canvas.drawLine(Offset(x(tick), axisY), Offset(x(tick), axisY + 4), line);
      final painter = TextPainter(
        text: TextSpan(text: format(tick), style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(x(tick) - painter.width / 2, axisY + 6));
    }

    // Box and whiskers, vertically centered above the axis.
    final centerY = axisY / 2;
    final boxHalf = (axisY * 0.25).clamp(12.0, 40.0);
    final box = Rect.fromLTRB(x(summary.q1), centerY - boxHalf, x(summary.q3), centerY + boxHalf);
    for (final end in [summary.min, summary.max]) {
      canvas.drawLine(Offset(x(end), centerY - boxHalf / 2), Offset(x(end), centerY + boxHalf / 2), line);
    }
    canvas
      ..drawLine(Offset(x(summary.min), centerY), Offset(x(summary.q1), centerY), line)
      ..drawLine(Offset(x(summary.q3), centerY), Offset(x(summary.max), centerY), line)
      ..drawRect(box, Paint()..color = boxColor.withValues(alpha: 0.35))
      ..drawRect(box, line)
      ..drawLine(
        Offset(x(summary.median), centerY - boxHalf),
        Offset(x(summary.median), centerY + boxHalf),
        Paint()
          ..color = boxColor
          ..strokeWidth = 3,
      );
  }

  @override
  bool shouldRepaint(_BoxPlotPainter oldDelegate) =>
      oldDelegate.summary != summary || oldDelegate.boxColor != boxColor || oldDelegate.lineColor != lineColor || oldDelegate.labelStyle != labelStyle;
}

/// Evenly spaced axis ticks covering [min]..[max], with a step of 1, 2 or
/// 5 ×10^k chosen for about five intervals. A single tick when [min] and
/// [max] are equal.
List<double> axisTicks(double min, double max) {
  if (max <= min) return [min];
  final rough = (max - min) / 5;
  var exponent = (math.log(rough) / math.ln10).floor();
  var multiple = [1, 2, 5, 10].firstWhere((m) => m * math.pow(10, exponent) >= rough);
  if (multiple == 10) {
    multiple = 1;
    exponent++;
  }
  // Ticks are i × multiple × 10^exponent. With a negative exponent,
  // dividing by the exact power of ten (rather than multiplying by an
  // inexact 0.1 or 0.01) keeps floating-point drift out of the values.
  final scale = math.pow(10, exponent.abs()).toDouble();
  double tick(int i) => exponent < 0 ? i * multiple / scale : i * multiple * scale;
  final step = tick(1);
  // The epsilon keeps a value that lands on a tick, give or take a
  // rounding error from the division, from adding a tick beyond it.
  final first = (min / step + 1e-9).floor();
  final last = (max / step - 1e-9).ceil();
  return [for (var i = first; i <= last; i++) tick(i)];
}

/// Pie slices are colored from a fixed palette with no other visual
/// encoding, so a legend mapping color to modality is the only way a
/// color-blind or low-vision user can tell them apart.
Widget _qualitativePieChart({required List<String> labels, required List<double> values}) {
  final percentages = roundedPercentages(values);
  const colors = AppTheme.chartPalette;

  return Column(
    children: [
      Expanded(
        child: PieChart(
          PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 40,
            sections: [
              for (var i = 0; i < values.length; i++)
                PieChartSectionData(
                  value: values[i],
                  color: colors[i % colors.length],
                  title: percentages.isEmpty ? '' : '${percentages[i]}%',
                  radius: 70,
                ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 4),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 4,
        children: [
          for (var i = 0; i < labels.length; i++)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 10, height: 10, color: colors[i % colors.length]),
                const SizedBox(width: 4),
                Text(labels[i], style: const TextStyle(fontSize: 12)),
              ],
            ),
        ],
      ),
    ],
  );
}

/// Whole-number percentages of [values] that always add up to exactly 100,
/// using the largest remainder method: floor every share, then hand the
/// missing points to the shares with the largest fractional parts (earliest
/// first on ties). Rounding each share on its own can add up to 99 or 101
/// (62.5 % and 37.5 % would both round up to 63 % + 38 %). Empty when the
/// values sum to zero.
List<int> roundedPercentages(List<double> values) {
  final total = values.fold<double>(0, (a, b) => a + b);
  if (total <= 0) return const [];

  final exact = [for (final v in values) v / total * 100];
  final result = [for (final p in exact) p.floor()];
  final missing = 100 - result.fold<int>(0, (a, b) => a + b);
  final byRemainder = List<int>.generate(values.length, (i) => i)
    ..sort((a, b) {
      final diff = (exact[b] - exact[b].floor()).compareTo(exact[a] - exact[a].floor());
      return diff != 0 ? diff : a.compareTo(b);
    });
  for (var k = 0; k < missing; k++) {
    result[byRemainder[k % values.length]]++;
  }
  return result;
}
