import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:flutter_math_fork/flutter_math.dart';

import '../../../core/models/course.dart';
import '../../themes/app_colors.dart';

/// Renders one [CourseBlock] of a course topic.
class CourseBlockView extends StatelessWidget {
  final CourseBlock block;

  const CourseBlockView(this.block, {super.key});

  @override
  Widget build(BuildContext context) => switch (block) {
    CourseText(:final text) => CourseRichText(text),
    CourseBullets(:final items) => _Bullets(items),
    final CourseFormula formula => _FormulaCard(formula),
    final CourseTable table => _ExampleTable(table),
    CourseTree(:final root) => _VariableTree(root),
  };
}

TextStyle _bodyStyle(BuildContext context) => Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 15, height: 1.5);

/// A paragraph where `**…**` marks bold terms.
class CourseRichText extends StatelessWidget {
  final String text;

  const CourseRichText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final parts = text.split('**');
    return Text.rich(
      TextSpan(
        style: _bodyStyle(context),
        children: [
          // Odd parts sit between a pair of ** markers.
          for (var i = 0; i < parts.length; i++)
            TextSpan(
              text: parts[i],
              style: i.isOdd ? const TextStyle(fontWeight: FontWeight.w700) : null,
            ),
        ],
      ),
    );
  }
}

class _Bullets extends StatelessWidget {
  final List<String> items;

  const _Bullets(this.items);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final item in items)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('•  ', style: _bodyStyle(context).copyWith(color: Theme.of(context).colorScheme.secondary)),
              Expanded(child: CourseRichText(item)),
            ],
          ),
        ),
    ],
  );
}

/// Background of the course's formula cards, table headers and search field.
Color coursePanelColor(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? AppColors.raisinBlack : AppColors.whiteSmoke;

/// The theme's default outline is plain black on the light theme, too
/// heavy for separators between list rows and table cells.
Color courseDividerColor(BuildContext context) => Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12);

/// A LaTeX formula that falls back to its source if it can't be parsed,
/// and scrolls sideways rather than overflow on narrow screens.
class CourseMath extends StatelessWidget {
  final String tex;
  final double fontSize;

  const CourseMath(this.tex, {this.fontSize = 15, super.key});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: fontSize, color: Theme.of(context).colorScheme.onSurface);
    return Math.tex(
      tex,
      textStyle: style,
      onErrorFallback: (_) => Text(tex, style: style),
    );
  }
}

class _FormulaCard extends StatelessWidget {
  final CourseFormula formula;

  const _FormulaCard(this.formula);

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: coursePanelColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accent, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (formula.label case final label?)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                label.toUpperCase(),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: accent),
              ),
            ),
          if (formula.text case final text?) CourseRichText(text),
          if (formula.tex case final tex?)
            Padding(
              padding: EdgeInsets.only(top: formula.text == null ? 4 : 12, bottom: 4),
              child: Center(
                child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: CourseMath(tex, fontSize: 20)),
              ),
            ),
          if (formula.legend.isNotEmpty) ...[
            const SizedBox(height: 8),
            // A table so the descriptions line up after the widest symbol.
            Table(
              columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
              children: [
                for (final symbol in formula.legend)
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8, right: 16),
                        // Math reports an intrinsic width a few pixels short
                        // of what it paints: let it spill into the padding.
                        child: OverflowBox(
                          alignment: Alignment.centerLeft,
                          maxWidth: double.infinity,
                          fit: OverflowBoxFit.deferToChild,
                          child: CourseMath(symbol.tex),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(symbol.text, style: _bodyStyle(context).copyWith(fontSize: 14, height: 1.4)),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ExampleTable extends StatelessWidget {
  final CourseTable table;

  const _ExampleTable(this.table);

  @override
  Widget build(BuildContext context) {
    final borderColor = courseDividerColor(context);
    final style = _bodyStyle(context).copyWith(fontSize: 14, height: 1.3);
    Widget cell(String text, {bool bold = false}) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: bold ? style.copyWith(fontWeight: FontWeight.w700) : style,
      ),
    );

    return Column(
      children: [
        Text(
          table.caption,
          textAlign: TextAlign.center,
          style: style.copyWith(fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 8),
        Table(
          border: TableBorder.all(color: borderColor, borderRadius: BorderRadius.circular(8)),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: BoxDecoration(color: coursePanelColor(context)),
              children: [for (final h in table.headers) cell(h, bold: true)],
            ),
            for (final row in table.rows) TableRow(children: [for (final c in row) cell(c, bold: identical(row, table.rows.last))]),
          ],
        ),
      ],
    );
  }
}

/// The root on top, its children side by side, and their own children
/// stacked below each of them.
class _VariableTree extends StatelessWidget {
  final CourseTreeNode root;

  const _VariableTree(this.root);

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return Column(
      children: [
        _NodeBox(root, filled: true),
        _Connector(color: accent),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, child) in root.children.indexed) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    _NodeBox(child, outlined: true),
                    for (final leaf in child.children) ...[
                      _Connector(color: accent),
                      _NodeBox(leaf),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _Connector extends StatelessWidget {
  final Color color;

  const _Connector({required this.color});

  @override
  Widget build(BuildContext context) => Container(width: 2, height: 12, color: color.withValues(alpha: 0.5));
}

class _NodeBox extends StatelessWidget {
  final CourseTreeNode node;
  final bool filled;
  final bool outlined;

  const _NodeBox(this.node, {this.filled = false, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    final textColor = filled ? Colors.white : Theme.of(context).colorScheme.onSurface;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: filled ? accent : coursePanelColor(context),
        borderRadius: BorderRadius.circular(10),
        border: outlined ? Border.all(color: accent, width: 1.5) : null,
      ),
      child: Column(
        children: [
          Text(
            node.label,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
          ),
          if (node.example case final example?)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                example,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Theme.of(context).hintColor),
              ),
            ),
        ],
      ),
    );
  }
}
