import 'package:flutter/material.dart';

import '../../../core/services/i18n/translations.g.dart';
import '../../../core/stats/raw_series.dart';

/// Shows a dialog where the user types or pastes a raw series ("3 5 5 7 3")
/// and returns the entry rows it tallies to, via [toRows] -- or null if the
/// user canceled. [hint] explains the expected format. [toRows] may throw
/// [RawSeriesException], shown as an inline error naming the bad value.
Future<List<List<String>>?> showRawSeriesDialog({
  required BuildContext context,
  required String hint,
  required List<List<String>> Function(String text) toRows,
}) => showDialog<List<List<String>>>(
  context: context,
  builder: (dialogContext) => _RawSeriesDialog(hint: hint, toRows: toRows),
);

class _RawSeriesDialog extends StatefulWidget {
  final String hint;
  final List<List<String>> Function(String text) toRows;

  const _RawSeriesDialog({required this.hint, required this.toRows});

  @override
  State<_RawSeriesDialog> createState() => _RawSeriesDialogState();
}

class _RawSeriesDialogState extends State<_RawSeriesDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final List<List<String>> rows;
    try {
      rows = widget.toRows(_controller.text);
    } on RawSeriesException catch (e) {
      setState(() => _error = context.t.rawSeriesInvalidValue(value: e.token));
      return;
    }
    if (rows.isEmpty) {
      setState(() => _error = context.t.rawSeriesEmpty);
      return;
    }
    Navigator.of(context).pop(rows);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.t.rawSeriesTitle),
    content: SizedBox(
      width: double.maxFinite,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.hint, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            minLines: 4,
            maxLines: 10,
            decoration: InputDecoration(border: const OutlineInputBorder(), errorText: _error, errorMaxLines: 3),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(context.t.cancel)),
      TextButton(onPressed: _submit, child: Text(context.t.rawSeriesSubmit)),
    ],
  );
}
