import 'package:flutter/material.dart';

import '../../../core/services/i18n/translations.g.dart';
import '../../../core/stats/raw_series.dart';

/// What the user typed in the raw series dialog: the series itself, then
/// one entry per extra field.
typedef RawSeriesInput = ({String text, List<String> extras});

/// Shows a dialog where the user types or pastes a raw series ("3 5 5 7 3")
/// and returns the entry rows it tallies to, via [toRows], along with what
/// the user typed -- or null if the user canceled. [hint] explains the
/// expected format.
///
/// [extraFields] labels optional fields shown under the series (e.g. the
/// continuous calculator's class start and width), left blank for
/// "automatic"; [toRows] gets their text in the same order. [initial]
/// prefills the dialog, e.g. with the previous input to adjust it.
///
/// [toRows] may throw [RawSeriesException], shown as an inline error.
Future<({List<List<String>> rows, RawSeriesInput input})?> showRawSeriesDialog({
  required BuildContext context,
  required String hint,
  required List<List<String>> Function(String text, List<String> extras) toRows,
  List<String> extraFields = const [],
  RawSeriesInput? initial,
}) => showDialog(
  context: context,
  builder: (dialogContext) => _RawSeriesDialog(hint: hint, toRows: toRows, extraFields: extraFields, initial: initial),
);

class _RawSeriesDialog extends StatefulWidget {
  final String hint;
  final List<List<String>> Function(String text, List<String> extras) toRows;
  final List<String> extraFields;
  final RawSeriesInput? initial;

  const _RawSeriesDialog({required this.hint, required this.toRows, required this.extraFields, required this.initial});

  @override
  State<_RawSeriesDialog> createState() => _RawSeriesDialogState();
}

class _RawSeriesDialogState extends State<_RawSeriesDialog> {
  late final _controller = TextEditingController(text: widget.initial?.text);
  late final _extraControllers = [
    for (var i = 0; i < widget.extraFields.length; i++)
      TextEditingController(text: (widget.initial?.extras.length ?? 0) > i ? widget.initial!.extras[i] : null),
  ];
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    for (final controller in _extraControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String _message(RawSeriesException e) => switch (e.error) {
    RawSeriesError.invalidValue => context.t.rawSeriesInvalidValue(value: e.token),
    RawSeriesError.invalidStart => context.t.rawSeriesInvalidStart(value: e.token),
    RawSeriesError.invalidWidth => context.t.rawSeriesInvalidWidth,
    RawSeriesError.startAboveMin => context.t.rawSeriesStartAboveMin(value: e.token),
    RawSeriesError.tooManyClasses => context.t.rawSeriesTooManyClasses(count: e.token),
  };

  void _submit() {
    final input = (text: _controller.text, extras: [for (final controller in _extraControllers) controller.text]);
    final List<List<String>> rows;
    try {
      rows = widget.toRows(input.text, input.extras);
    } on RawSeriesException catch (e) {
      setState(() => _error = _message(e));
      return;
    }
    if (rows.isEmpty) {
      setState(() => _error = context.t.rawSeriesEmpty);
      return;
    }
    Navigator.of(context).pop((rows: rows, input: input));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.t.rawSeriesTitle),
    content: SizedBox(
      width: double.maxFinite,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.hint, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            // Above the series, so the keyboard it brings up can't hide them.
            if (widget.extraFields.isNotEmpty) ...[
              Row(
                spacing: 12,
                children: [
                  for (final (index, label) in widget.extraFields.indexed)
                    Expanded(
                      child: TextField(
                        controller: _extraControllers[index],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: label,
                          hintText: context.t.rawSeriesAuto,
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _controller,
              autofocus: true,
              // Shorter with extra fields, so the dialog still fits above
              // the keyboard.
              minLines: widget.extraFields.isEmpty ? 4 : 3,
              maxLines: widget.extraFields.isEmpty ? 10 : 6,
              decoration: InputDecoration(border: const OutlineInputBorder(), errorText: _error, errorMaxLines: 3),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(context.t.cancel)),
      TextButton(onPressed: _submit, child: Text(context.t.rawSeriesSubmit)),
    ],
  );
}
