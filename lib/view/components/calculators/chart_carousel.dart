import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/stats/rounding.dart';
import '../../../core/tools/constants/chart_options.dart';
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
    if (widget.charts.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 260,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
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
                    backgroundColor: i == _page ? AppTheme.primaryColor : Colors.grey.shade400,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// Builds one chart widget per selected [QuantitativeChartType], from a
/// discrete/continuous result's `xi`/`ni` arrays -- shared by the Discrete
/// and Continuous screens.
List<Widget> buildQuantitativeCharts({
  required List<double> xi,
  required List<double> ni,
  required Set<QuantitativeChartType> types,
}) => [
  if (types.contains(QuantitativeChartType.bar)) _quantitativeBarChart(xi: xi, ni: ni),
  if (types.contains(QuantitativeChartType.line)) _quantitativeLineChart(xi: xi, ni: ni),
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

Widget _bottomLabel(List<String> labels, double value) {
  final index = value.toInt();
  if (index < 0 || index >= labels.length) return const SizedBox.shrink();
  return SideTitleWidget(
    axisSide: AxisSide.bottom,
    space: 6,
    child: Text(labels[index], style: const TextStyle(fontSize: 11)),
  );
}

/// Simple bar chart of arbitrary (label, value) pairs -- also used for the
/// Backups screen's mini-chart, which only ever needs one plain view of
/// the saved xi/ni.
Widget qualitativeBarChart({required List<String> labels, required List<double> values}) => BarChart(
  BarChartData(
    barTouchData: BarTouchData(enabled: false),
    titlesData: FlTitlesData(
      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) => _bottomLabel(labels, v), reservedSize: 28)),
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
      topTitles: const AxisTitles(),
      rightTitles: const AxisTitles(),
    ),
    borderData: FlBorderData(show: false),
    barGroups: [
      for (var i = 0; i < values.length; i++)
        BarChartGroupData(
          x: i,
          barRods: [BarChartRodData(toY: values[i], color: AppTheme.primaryColor, width: 16)],
        ),
    ],
  ),
);

Widget _quantitativeBarChart({required List<double> xi, required List<double> ni}) => qualitativeBarChart(labels: xi.map(noZero).toList(), values: ni);

Widget _quantitativeLineChart({required List<double> xi, required List<double> ni}) {
  final labels = xi.map(noZero).toList();
  return LineChart(
    LineChartData(
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) => _bottomLabel(labels, v), reservedSize: 28)),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
        topTitles: const AxisTitles(),
        rightTitles: const AxisTitles(),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: [for (var i = 0; i < ni.length; i++) FlSpot(i.toDouble(), ni[i])],
          color: AppTheme.primaryColor,
        ),
      ],
    ),
  );
}

Widget _qualitativePieChart({required List<String> labels, required List<double> values}) {
  final total = values.fold<double>(0, (a, b) => a + b);
  const colors = AppTheme.chartPalette;

  return PieChart(
    PieChartData(
      sectionsSpace: 2,
      centerSpaceRadius: 40,
      sections: [
        for (var i = 0; i < values.length; i++)
          PieChartSectionData(
            value: values[i],
            color: colors[i % colors.length],
            title: total == 0 ? '' : '${(values[i] / total * 100).round()}%',
            radius: 70,
          ),
      ],
    ),
  );
}
