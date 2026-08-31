import 'package:flutter/material.dart';

/// A header that expands/collapses a checkbox column below it -- mirrors the
/// legacy "Calculs" expandable panel on each calculator screen.
class CollapsibleChecklist extends StatelessWidget {
  final String title;
  final bool expanded;
  final VoidCallback onHeaderTap;
  final Widget child;

  const CollapsibleChecklist({
    required this.title,
    required this.expanded,
    required this.onHeaderTap,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Card(
    child: Column(
      children: [
        InkWell(
          onTap: onHeaderTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(title),
                Icon(expanded ? Icons.expand_less : Icons.expand_more),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
          crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    ),
  );
}
