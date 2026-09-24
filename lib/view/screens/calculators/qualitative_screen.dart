import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/backups/backup_data.dart';
import '../../../core/providers/calculators/calculator_types.dart';
import '../../../core/providers/calculators/qualitative_provider.dart';
import '../../../core/providers/settings/settings_provider.dart';
import '../../../core/services/i18n/translations.g.dart';
import '../../../core/stats/rounding.dart';
import '../../../core/tools/functions/number_parsing.dart';
import '../../components/calculators/bulk_import_dialog.dart';
import '../../components/calculators/calculator_actions.dart';
import '../../components/calculators/calculator_form.dart';
import '../../components/calculators/chart_carousel.dart';
import '../../components/calculators/qualitative_explanation.dart';
import '../../components/calculators/share_text.dart';
import '../../components/calculators/stats_table.dart';

class QualitativeScreen extends ConsumerStatefulWidget {
  const QualitativeScreen({super.key});

  @override
  ConsumerState<QualitativeScreen> createState() => _QualitativeScreenState();
}

class _QualitativeScreenState extends ConsumerState<QualitativeScreen> with AutomaticKeepAliveClientMixin {
  // Modality, value.
  final _entries = EntryRows(2);

  // Without this, the TabBarView disposes this screen (and its in-progress
  // entry rows) whenever the user switches to another tab and back.
  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _entries.dispose();
    super.dispose();
  }

  Future<void> _bulkImport() async {
    final rows = await showBulkImportDialog(
      context: context,
      fieldLabels: [context.t.modalityLabel, context.t.effectifLabel],
    );
    if (rows != null) setState(() => _entries.importRows(rows));
  }

  void _calculate() => showCalculationError(
    context,
    ref.read(qualitativeCalculatorProvider.notifier).calculate(_entries.column(0), _entries.column(1)),
  );

  Future<void> _save() async {
    final state = ref.read(qualitativeCalculatorProvider);
    final result = state.result;
    if (result == null) return;

    await saveCalculationBackup(
      context,
      data: BackupData(
        kind: BackupKind.qualitative,
        columns: [result.modalities, result.effectifs],
        selectedStats: [for (final option in state.selectedStats) option.name],
        precision: result.precision,
      ),
      resolutionHtml: buildQualitativeExplanationHtml(result, state.selectedStats),
      xi: List<int>.generate(result.modalities.length, (i) => i).join('_'),
      ni: result.effectifs.join('_'),
    );
  }

  Future<void> _share() async {
    final state = ref.read(qualitativeCalculatorProvider);
    final result = state.result;
    if (result == null) return;

    await shareCalculationText(context, buildQualitativeShareText(result, state.selectedStats));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(qualitativeCalculatorProvider);
    final notifier = ref.read(qualitativeCalculatorProvider.notifier);
    final result = state.result;
    String fmt(double v) => noZero(v, decimalSeparator: decimalSeparatorForLocale(LocaleSettings.currentLocale.languageCode));

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.t.calcVarN, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            EntryRowsCard(
              rows: _entries,
              labels: [context.t.modalityLabel, context.t.effectifLabel],
              keyboardTypes: const [null, numericKeyboard],
              onAdd: () => setState(_entries.add),
              onRemove: (i) => setState(() => _entries.removeAt(i)),
              onBulkImport: _bulkImport,
            ),
            const SizedBox(height: 12),
            StatOptionsChecklist<QualitativeStatOption>(
              options: QualitativeStatOption.values,
              selected: state.selectedStats,
              label: (option) => qualitativeStatOptionLabel(context, option),
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
                    context.t.qltTabTitle1,
                    context.t.qltTabTitle2,
                    context.t.qltTabTitle3,
                    context.t.qltTabTitle4,
                    context.t.qltTabTitle5,
                  ],
                  rows: [
                    for (var i = 0; i < result.modalities.length; i++)
                      [
                        result.modalities[i],
                        fmt(result.effectifs[i]),
                        fmt(result.frequencies[i]),
                        fmt(result.cumulativeEffectifs[i]),
                        fmt(result.cumulativeFrequencies[i]),
                      ],
                  ],
                ),
              ),
              if (state.selectedStats.contains(QualitativeStatOption.charts)) ...[
                const SizedBox(height: 16),
                ChartCarousel(
                  charts: buildQualitativeCharts(
                    modalities: result.modalities,
                    effectifs: result.effectifs,
                    types: ref.watch(settingsProvider).qualitativeChartTypes,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              QualitativeExplanation(result: result, selectedStats: state.selectedStats),
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
