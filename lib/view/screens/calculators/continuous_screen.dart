import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/data/backups/backups_repository.dart';
import '../../../core/models/backup_model.dart';
import '../../../core/providers/calculators/calculator_types.dart';
import '../../../core/providers/calculators/continuous_provider.dart';
import '../../../core/providers/settings/settings_provider.dart';
import '../../../core/services/di/locator.dart';
import '../../../core/services/i18n/translations.g.dart';
import '../../../core/stats/rounding.dart';
import '../../../core/tools/functions/number_parsing.dart';
import '../../components/calculators/bulk_import_dialog.dart';
import '../../components/calculators/chart_carousel.dart';
import '../../components/calculators/collapsible_checklist.dart';
import '../../components/calculators/continuous_explanation.dart';
import '../../components/calculators/deletable_entry_row.dart';
import '../../components/calculators/share_text.dart';
import '../../components/calculators/stats_table.dart';

class ContinuousScreen extends ConsumerStatefulWidget {
  const ContinuousScreen({super.key});

  @override
  ConsumerState<ContinuousScreen> createState() => _ContinuousScreenState();
}

class _EntryControllers {
  final l1 = TextEditingController();
  final l2 = TextEditingController();
  final ni = TextEditingController();

  void dispose() {
    l1.dispose();
    l2.dispose();
    ni.dispose();
  }
}

class _ContinuousScreenState extends ConsumerState<ContinuousScreen> with AutomaticKeepAliveClientMixin {
  final List<_EntryControllers> _entries = [];

  // Without this, the TabBarView disposes this screen (and its in-progress
  // entry rows) whenever the user switches to another tab and back.
  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    for (final entry in _entries) {
      entry.dispose();
    }
    super.dispose();
  }

  void _addEntry() => setState(() => _entries.add(_EntryControllers()));

  void _removeEntry(int index) => setState(() {
    _entries.removeAt(index).dispose();
  });

  Future<void> _bulkImport() async {
    final rows = await showBulkImportDialog(context: context, fieldLabels: const ['L1', 'L2', 'Ni']);
    if (rows == null) return;

    setState(() {
      _entries.removeWhere((e) => e.l1.text.trim().isEmpty && e.l2.text.trim().isEmpty && e.ni.text.trim().isEmpty);
      for (final row in rows) {
        _entries.add(
          _EntryControllers()
            ..l1.text = row[0]
            ..l2.text = row[1]
            ..ni.text = row[2],
        );
      }
    });
  }

  void _calculate() {
    final notifier = ref.read(continuousCalculatorProvider.notifier);
    final error = notifier.calculate(
      _entries.map((e) => e.l1.text).toList(),
      _entries.map((e) => e.l2.text).toList(),
      _entries.map((e) => e.ni.text).toList(),
    );

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    }
  }

  String _errorMessage(CalculationError error) => switch (error) {
    CalculationError.insufficientData => context.t.insufficientData,
    CalculationError.emptyField => context.t.emptyFieldError,
    CalculationError.syntaxError => context.t.syntaxError,
    CalculationError.invalidValue => context.t.invalidValueError,
  };

  String _optionLabel(StatOption option) => switch (option) {
    StatOption.mean => context.t.meanCheckbox,
    StatOption.median => context.t.medianCheckbox,
    StatOption.quartiles => context.t.quartilesCheckbox,
    StatOption.mode => context.t.modeCheckbox,
    StatOption.variance => context.t.varianceCheckbox,
    StatOption.covariance => context.t.covarianceCheckbox,
    StatOption.standardDeviation => context.t.standardDeviationCheckbox,
    StatOption.coefficientOfVariation => context.t.coefficientOfVariationCheckbox,
    StatOption.charts => context.t.chartsCheckbox,
  };

  Future<String?> _promptForName() => showDialog<String>(
    context: context,
    builder: (dialogContext) {
      final controller = TextEditingController();
      return AlertDialog(
        title: Text(context.t.saveStats),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: context.t.statsName),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(context.t.cancel)),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(context.t.namedThisStats)));
                return;
              }
              Navigator.of(dialogContext).pop(name);
            },
            child: Text(context.t.save),
          ),
        ],
      );
    },
  );

  Future<void> _save() async {
    final calculatorState = ref.read(continuousCalculatorProvider);
    final result = calculatorState.result;
    if (result == null) return;

    final name = await _promptForName();
    if (name == null) return;

    final now = DateTime.now();
    final date =
        '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year} - '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    await locator<BackupsRepository>().add(
      Backup(
        name: name,
        resolutionHtml: buildContinuousExplanationHtml(
          result,
          calculatorState.l1,
          calculatorState.l2,
          calculatorState.selectedStats,
          ref.read(continuousCalculatorProvider.notifier).getDecimalPrecision(),
        ),
        xi: result.xi.join('_'),
        ni: result.ni.join('_'),
        date: date,
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t.safeguardDone)));
    }
  }

  Future<void> _share() async {
    final calculatorState = ref.read(continuousCalculatorProvider);
    final result = calculatorState.result;
    if (result == null) return;

    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: buildContinuousShareText(result, calculatorState.l1, calculatorState.l2, calculatorState.selectedStats),
        sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(continuousCalculatorProvider);
    final notifier = ref.read(continuousCalculatorProvider.notifier);
    final result = state.result;
    String fmt(double v) => noZero(v, decimalSeparator: decimalSeparatorForLocale(LocaleSettings.currentLocale.languageCode));

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.t.calcVarC, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    for (var i = 0; i < _entries.length; i++)
                      DeletableEntryRow(
                        fields: [
                          TextField(
                            controller: _entries[i].l1,
                            decoration: const InputDecoration(labelText: 'L1'),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                          ),
                          TextField(
                            controller: _entries[i].l2,
                            decoration: const InputDecoration(labelText: 'L2'),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                          ),
                          TextField(
                            controller: _entries[i].ni,
                            decoration: const InputDecoration(labelText: 'Ni'),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                          ),
                        ],
                        onDelete: () => _removeEntry(i),
                      ),
                    Wrap(
                      children: [
                        TextButton.icon(
                          onPressed: _addEntry,
                          icon: const Icon(Icons.add_circle_outline),
                          label: Text(context.t.addEntry),
                        ),
                        TextButton.icon(
                          onPressed: _bulkImport,
                          icon: const Icon(Icons.content_paste),
                          label: Text(context.t.bulkImportAction),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            CollapsibleChecklist(
              title: context.t.calculations,
              expanded: state.showCalculations,
              onHeaderTap: notifier.toggleShowCalculations,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(context.t.selectAll),
                    value: state.isSelected,
                    onChanged: (value) => notifier.toggleAll(value ?? false),
                  ),
                  for (final option in StatOption.values)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_optionLabel(option)),
                      value: state.selectedStats.contains(option),
                      onChanged: (value) => notifier.toggleStat(option, value ?? false),
                    ),
                ],
              ),
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
                    types: ref.read(settingsProvider.notifier).getContinuousChartTypes(),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ContinuousExplanation(
                result: result,
                l1: state.l1,
                l2: state.l2,
                selectedStats: state.selectedStats,
                precision: notifier.getDecimalPrecision(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(context.t.save),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _share,
                      icon: const Icon(Icons.share_outlined),
                      label: Text(context.t.share),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
