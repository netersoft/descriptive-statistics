import 'package:flutter/widgets.dart';

import '../../services/i18n/translations.g.dart';

/// Chart representations offered for discrete/continuous (quantitative)
/// series -- a reduced set of the legacy app's graphikA/graphikB options
/// (line, v_bar, h_bar, bubble, point, line_point). Horizontal bars,
/// bubbles and a separate scatter/line-with-dots variant are dropped: bar
/// and line already cover what those alternate renderings communicate for
/// a small classroom dataset, and fl_chart has no native horizontal-bar
/// or bubble chart to port them onto faithfully. The box plot is new to
/// this app.
enum QuantitativeChartType { bar, line, boxPlot }

/// Chart representations for qualitative series -- matches the legacy
/// app's graphikC options (cercle, bar) exactly.
enum QualitativeChartType { bar, pie }

String quantitativeChartTypeLabel(BuildContext context, QuantitativeChartType type) => switch (type) {
  QuantitativeChartType.bar => context.t.chartTypeBar,
  QuantitativeChartType.line => context.t.chartTypeLine,
  QuantitativeChartType.boxPlot => context.t.chartTypeBoxPlot,
};

String qualitativeChartTypeLabel(BuildContext context, QualitativeChartType type) => switch (type) {
  QualitativeChartType.bar => context.t.chartTypeBar,
  QualitativeChartType.pie => context.t.chartTypePie,
};
