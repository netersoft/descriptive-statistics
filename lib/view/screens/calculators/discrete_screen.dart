import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/backups/backup_data.dart';
import '../../../core/providers/calculators/calculator_types.dart';
import '../../../core/providers/calculators/discrete_provider.dart';
import '../../../core/providers/settings/settings_provider.dart';
import '../../../core/services/i18n/translations.g.dart';
import '../../../core/stats/raw_series.dart';
import '../../../core/stats/rounding.dart';
import '../../../core/tools/functions/number_parsing.dart';
import '../../components/calculators/bulk_import_dialog.dart';
import '../../components/calculators/calculator_actions.dart';
import '../../components/calculators/calculator_form.dart';
import '../../components/calculators/chart_carousel.dart';
import '../../components/calculators/discrete_explanation.dart';
import '../../components/calculators/raw_series_dialog.dart';
import '../../components/calculators/share_text.dart';
import '../../components/calculators/stats_table.dart';

class DiscreteScreen extends ConsumerStatefulWidget {
  const DiscreteScreen({super.key});

  @override
  ConsumerState<DiscreteScreen> createState() => _DiscreteScreenState();
}

class _DiscreteScreenState extends ConsumerState<DiscreteScreen> with AutomaticKeepAliveClientMixin {
  // Xi, Ni.
  final _entries = EntryRows(2);

  // Without this, the TabBarView disposes this screen (and its in-progress
  // entry rows) whenever the user switches to another tab and back.
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // A backup may have been loaded before this tab was first built.
    final loaded = ref.read(discreteCalculatorProvider).loadedRows;
    if (loaded != null) _entries.replaceRows(loaded);
  }

  @override
  void dispose() {
    _entries.dispose();
    super.dispose();
  }

  Future<void> _bulkImport() async {
    final rows = await showBulkImportDialog(context: context, fieldLabels: const ['Xi', 'Ni']);
    if (rows != null) setState(() => _entries.importRows(rows));
  }

  Future<void> _rawSeries() async {
    final separator = decimalSeparatorForLocale(LocaleSettings.currentLocale.languageCode);
    final rows = await showRawSeriesDialog(
      context: context,
      hint: context.t.rawSeriesNumericHint,
      toRows: (text) => [
        for (final (:value, :count) in tallyNumericSeries(text)) [noZero(value, decimalSeparator: separator), '$count'],
      ],
    );
    if (rows != null) setState(() => _entries.importRows(rows));
  }

  void _calculate() => showCalculationError(
    context,
    ref.read(discreteCalculatorProvider.notifier).calculate(_entries.column(0), _entries.column(1)),
  );

  Future<void> _save() async {
    final state = ref.read(discreteCalculatorProvider);
    final result = state.result;
    if (result == null) return;

    await saveCalculationBackup(
      context,
      data: BackupData(
        kind: BackupKind.discrete,
        columns: [result.xi, result.ni],
        selectedStats: [for (final option in state.selectedStats) option.name],
        precision: result.precision,
      ),
      resolutionHtml: buildDiscreteExplanationHtml(result, state.selectedStats),
      xi: result.xi.join('_'),
      ni: result.ni.join('_'),
    );
  }

  Future<void> _share() async {
    final state = ref.read(discreteCalculatorProvider);
    final result = state.result;
    if (result == null) return;

    await shareCalculationText(context, buildDiscreteShareText(result, state.selectedStats));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    ref.listen(discreteCalculatorProvider.select((state) => state.loadCount), (_, _) {
      setState(() => _entries.replaceRows(ref.read(discreteCalculatorProvider).loadedRows!));
    });
    final state = ref.watch(discreteCalculatorProvider);
    final notifier = ref.read(discreteCalculatorProvider.notifier);
    final result = state.result;
    String fmt(double v) => noZero(v, decimalSeparator: decimalSeparatorForLocale(LocaleSettings.currentLocale.languageCode));

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.t.calcVarD, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            EntryRowsCard(
              rows: _entries,
              labels: const ['Xi', 'Ni'],
              keyboardTypes: const [numericKeyboard, numericKeyboard],
              onAdd: () => setState(_entries.add),
              onRemove: (i) => setState(() => _entries.removeAt(i)),
              onBulkImport: _bulkImport,
              onRawSeries: _rawSeries,
            ),
            const SizedBox(height: 12),
            StatOptionsChecklist<StatOption>(
              options: StatOption.values,
              selected: state.selectedStats,
              label: (option) => statOptionLabel(context, option),
              expanded: state.showCalculations,
              onHeaderTap: notifier.toggleShowCalculations,
              onToggleAll: notifier.toggleAll,
              onToggle: notifier.toggleStat,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: _calculate, child: Text(context.t.calculate)),
            ),
            if (result != null) ...[
              const SizedBox(height: 24),
              Text(
                context.t.statsTable,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Center(
                child: StatsTable(
                  headers: [
                    context.t.tableXi,
                    context.t.tableNi,
                    context.t.tableXini,
                    context.t.tableXi2ni,
                    context.t.tableUp,
                    context.t.tableDown,
                  ],
                  rows: [
                    for (var i = 0; i < result.xi.length; i++)
                      [
                        fmt(result.xi[i]),
                        fmt(result.ni[i]),
                        fmt(result.xini[i]),
                        fmt(result.xi2ni[i]),
                        fmt(result.cumulativeAscending[i]),
                        fmt(result.cumulativeDescending[i]),
                      ],
                  ],
                ),
              ),
              if (state.selectedStats.contains(StatOption.charts)) ...[
                const SizedBox(height: 16),
                ChartCarousel(
                  charts: buildQuantitativeCharts(
                    xi: result.xi,
                    ni: result.ni,
                    types: ref.watch(settingsProvider).discreteChartTypes,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              DiscreteExplanation(result: result, selectedStats: state.selectedStats),
              const SizedBox(height: 16),
              ResultActions(onSave: _save, onShare: _share),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
