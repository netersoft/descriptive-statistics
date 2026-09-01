import 'package:flutter/material.dart';

import '../../../core/services/i18n/translations.g.dart';

/// One data-entry row: a set of [fields] side by side, with a trailing
/// delete button. Used by all three calculator screens (discrete/continuous
/// have 2/3 text fields per row; qualitative has 2).
class DeletableEntryRow extends StatelessWidget {
  final List<Widget> fields;
  final VoidCallback onDelete;

  const DeletableEntryRow({required this.fields, required this.onDelete, super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        for (final field in fields)
          Expanded(
            child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: field),
          ),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          tooltip: context.t.delete,
          onPressed: onDelete,
        ),
      ],
    ),
  );
}
