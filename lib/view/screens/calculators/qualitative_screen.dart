import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/data/backups/backups_repository.dart';
import '../../../core/models/backup_model.dart';
import '../../../core/providers/calculators/calculator_types.dart';
import '../../../core/providers/calculators/qualitative_provider.dart';
import '../../../core/providers/settings/settings_provider.dart';
import '../../../core/services/di/locator.dart';
import '../../../core/services/i18n/translations.g.dart';
import '../../../core/stats/rounding.dart';
import '../../../core/tools/functions/number_parsing.dart';
import '../../components/calculators/bulk_import_dialog.dart';
import '../../components/calculators/chart_carousel.dart';
import '../../components/calculators/collapsible_checklist.dart';
import '../../components/calculators/deletable_entry_row.dart';
import '../../components/calculators/qualitative_explanation.dart';
import '../../components/calculators/share_text.dart';
import '../../components/calculators/stats_table.dart';

class QualitativeScreen extends ConsumerStatefulWidget {
  const QualitativeScreen({super.key});

  @override
  ConsumerState<QualitativeScreen> createState() => _QualitativeScreenState();
}

class _EntryControllers {
  final modality = TextEditingController();
  final value = TextEditingController();

  void dispose() {
    modality.dispose();
    value.dispose();
  }
}

class _QualitativeScreenState extends ConsumerState<QualitativeScreen> with AutomaticKeepAliveClientMixin {
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
    final rows = await showBulkImportDialog(
      context: context,
      fieldLabels: [context.t.modalityLabel, context.t.effectifLabel],
    );
    if (rows == null) return;

    setState(() {
      _entries.removeWhere((e) => e.modality.text.trim().isEmpty && e.value.text.trim().isEmpty);
      for (final row in rows) {
        _entries.add(_EntryControllers()..modality.text = row[0]..value.text = row[1]);
      }
    });
  }

  void _calculate() {
    final notifier = ref.read(qualitativeCalculatorProvider.notifier);
    final error = notifier.calculate(
      _entries.map((e) => e.modality.text).toList(),
      _entries.map((e) => e.value.text).toList(),
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
    CalculationError.overlappingClasses => context.t.overlappingClassesError,
  };

  String _optionLabel(QualitativeStatOption option) => switch (option) {
    QualitativeStatOption.mean => context.t.meanCheckbox,
    QualitativeStatOption.mode => context.t.modeCheckbox,
    QualitativeStatOption.charts => context.t.chartsCheckbox,
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
    final calculatorState = ref.read(qualitativeCalculatorProvider);
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
        resolutionHtml: buildQualitativeExplanationHtml(result, calculatorState.selectedStats),
        xi: List<int>.generate(result.modalities.length, (i) => i).join('_'),
        ni: result.effectifs.join('_'),
        date: date,
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t.safeguardDone)));
    }
  }

  Future<void> _share() async {
    final calculatorState = ref.read(qualitativeCalculatorProvider);
    final result = calculatorState.result;
    if (result == null) return;

    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: buildQualitativeShareText(result, calculatorState.selectedStats),
        sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    for (var i = 0; i < _entries.length; i++)
                      DeletableEntryRow(
                        fields: [
                          TextField(
                            controller: _entries[i].modality,
                            decoration: InputDecoration(labelText: context.t.modalityLabel),
                          ),
                          TextField(
                            controller: _entries[i].value,
                            decoration: InputDecoration(labelText: context.t.effectifLabel),
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
                  for (final option in QualitativeStatOption.values)
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
                    types: ref.read(settingsProvider.notifier).getQualitativeChartTypes(),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              QualitativeExplanation(result: result, selectedStats: state.selectedStats),
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
