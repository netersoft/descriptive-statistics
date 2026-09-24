import 'package:flutter/material.dart';

import '../../../core/services/i18n/translations.g.dart';
import 'collapsible_checklist.dart';
import 'deletable_entry_row.dart';

/// Keyboard for numeric entry fields: '-' for negative values, and a
/// decimal key (',' or '.' depending on the locale -- both are accepted).
const numericKeyboard = TextInputType.numberWithOptions(decimal: true, signed: true);

/// The text controllers behind a calculator's data-entry rows, [fieldCount]
/// per row (Xi/Ni, L1/L2/Ni, modality/value). Owned by the screen's State,
/// which must call [dispose].
class EntryRows {
  final int fieldCount;
  final List<List<TextEditingController>> _rows = [];

  EntryRows(this.fieldCount);

  int get length => _rows.length;

  List<TextEditingController> operator [](int index) => _rows[index];

  void add([List<String>? values]) => _rows.add([
    for (var field = 0; field < fieldCount; field++) TextEditingController(text: values?[field] ?? ''),
  ]);

  void removeAt(int index) {
    for (final controller in _rows.removeAt(index)) {
      controller.dispose();
    }
  }

  /// Appends pasted [rows], first dropping rows the user left entirely
  /// blank so they don't sit empty above the imported data.
  void importRows(List<List<String>> rows) {
    for (var i = _rows.length - 1; i >= 0; i--) {
      if (_rows[i].every((controller) => controller.text.trim().isEmpty)) removeAt(i);
    }
    rows.forEach(add);
  }

  /// The text of [field] in every row, top to bottom.
  List<String> column(int field) => [for (final row in _rows) row[field].text];

  void dispose() {
    for (final row in _rows) {
      for (final controller in row) {
        controller.dispose();
      }
    }
  }
}

/// The card holding a calculator's entry rows, with its "add an entry" and
/// "import data" actions -- plus "raw series" when [onRawSeries] is set.
/// [labels] and [keyboardTypes] give each field's label and keyboard, in
/// row order.
class EntryRowsCard extends StatelessWidget {
  final EntryRows rows;
  final List<String> labels;
  final List<TextInputType?> keyboardTypes;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final VoidCallback onBulkImport;
  final VoidCallback? onRawSeries;

  const EntryRowsCard({
    required this.rows,
    required this.labels,
    required this.keyboardTypes,
    required this.onAdd,
    required this.onRemove,
    required this.onBulkImport,
    this.onRawSeries,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            DeletableEntryRow(
              fields: [
                for (var field = 0; field < rows.fieldCount; field++)
                  TextField(
                    controller: rows[i][field],
                    decoration: InputDecoration(labelText: labels[field]),
                    keyboardType: keyboardTypes[field],
                  ),
              ],
              onDelete: () => onRemove(i),
            ),
          Wrap(
            children: [
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_circle_outline),
                label: Text(context.t.addEntry),
              ),
              TextButton.icon(
                onPressed: onBulkImport,
                icon: const Icon(Icons.content_paste),
                label: Text(context.t.bulkImportAction),
              ),
              if (onRawSeries != null)
                TextButton.icon(
                  onPressed: onRawSeries,
                  icon: const Icon(Icons.format_list_numbered),
                  label: Text(context.t.rawSeriesAction),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// The collapsible "Calculs" panel: a "select all" checkbox followed by one
/// checkbox per stat [options] entry.
class StatOptionsChecklist<T> extends StatelessWidget {
  final List<T> options;
  final Set<T> selected;
  final String Function(T) label;
  final bool expanded;
  final VoidCallback onHeaderTap;
  final ValueChanged<bool> onToggleAll;
  final void Function(T option, bool selected) onToggle;

  const StatOptionsChecklist({
    required this.options,
    required this.selected,
    required this.label,
    required this.expanded,
    required this.onHeaderTap,
    required this.onToggleAll,
    required this.onToggle,
    super.key,
  });

  @override
  Widget build(BuildContext context) => CollapsibleChecklist(
    title: context.t.calculations,
    expanded: expanded,
    onHeaderTap: onHeaderTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(context.t.selectAll),
          value: selected.length == options.length,
          onChanged: (value) => onToggleAll(value ?? false),
        ),
        for (final option in options)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(label(option)),
            value: selected.contains(option),
            onChanged: (value) => onToggle(option, value ?? false),
          ),
      ],
    ),
  );
}

/// The Save / Share buttons shown under a calculation's result.
class ResultActions extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback onShare;

  const ResultActions({required this.onSave, required this.onShare, super.key});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: onSave,
          icon: const Icon(Icons.save_outlined),
          label: Text(context.t.save),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: OutlinedButton.icon(
          onPressed: onShare,
          icon: const Icon(Icons.share_outlined),
          label: Text(context.t.share),
        ),
      ),
    ],
  );
}
