import 'package:flutter/material.dart';

/// A bordered table of [headers] and [rows], matching the legacy stats
/// table's shape (Xi/Ni/XiNi/Xi²Ni/Ni+/Ni- for discrete/continuous,
/// modality/effectif/frequency/etc for qualitative).
class StatsTable extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> rows;

  const StatsTable({required this.headers, required this.rows, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.dividerColor;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        border: TableBorder.all(color: borderColor),
        defaultColumnWidth: const IntrinsicColumnWidth(),
        children: [
          TableRow(
            decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest),
            children: [
              for (final header in headers) _cell(header, bold: true),
            ],
          ),
          for (final row in rows)
            TableRow(
              children: [
                for (final value in row) _cell(value),
              ],
            ),
        ],
      ),
    );
  }

  Widget _cell(String text, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal),
    ),
  );
}
