import 'package:flutter/material.dart';

import '../../../core/services/i18n/translations.g.dart';

/// Splits a pasted row on tabs or semicolons -- not plain spaces or commas,
/// since a qualitative modality name may legitimately contain a space, and
/// a comma is also a valid decimal separator within a field.
final _fieldSeparator = RegExp(r'[\t;]+');

/// Shows a dialog letting the user paste multiple rows of data at once
/// (e.g. copied from a spreadsheet) instead of typing them in one by one.
/// [fieldLabels] names each column (e.g. `['Xi', 'Ni']`) for the format
/// hint and error message. Returns the parsed fields per non-empty row, or
/// null if the user canceled.
///
/// Numeric validity isn't checked here -- fields are re-validated the same
/// way manually typed rows are, when the user taps Calculate.
Future<List<List<String>>?> showBulkImportDialog({
  required BuildContext context,
  required List<String> fieldLabels,
}) => showDialog<List<List<String>>>(
  context: context,
  builder: (dialogContext) => _BulkImportDialog(fieldLabels: fieldLabels),
);

class _BulkImportDialog extends StatefulWidget {
  final List<String> fieldLabels;

  const _BulkImportDialog({required this.fieldLabels});

  @override
  State<_BulkImportDialog> createState() => _BulkImportDialogState();
}

class _BulkImportDialogState extends State<_BulkImportDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final lines = _controller.text.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();

    final rows = <List<String>>[];
    for (final line in lines) {
      final fields = line.split(_fieldSeparator).map((field) => field.trim()).toList();
      if (fields.length != widget.fieldLabels.length) {
        setState(() => _error = '${context.t.bulkImportInvalidFormat} ${widget.fieldLabels.join(' ; ')}');
        return;
      }
      rows.add(fields);
    }

    if (rows.isEmpty) {
      setState(() => _error = '${context.t.bulkImportInvalidFormat} ${widget.fieldLabels.join(' ; ')}');
      return;
    }

    Navigator.of(context).pop(rows);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.t.bulkImportTitle),
    content: SizedBox(
      width: double.maxFinite,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.t.bulkImportHint, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            minLines: 5,
            maxLines: 10,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: widget.fieldLabels.join(' ; '),
              errorText: _error,
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(context.t.cancel)),
      TextButton(onPressed: _submit, child: Text(context.t.bulkImportSubmit)),
    ],
  );
}
