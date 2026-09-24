import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

/// [HtmlWidget] for the app's legacy-style HTML (course, step-by-step
/// explanations, saved backups). Their `<font color>` names were picked
/// for a white background, and pure blue/green are unreadable on the dark
/// theme, so they're swapped for lighter tints there. Done at render time
/// rather than when the HTML is built, so backups saved earlier (whose HTML
/// is stored as-is) benefit too.
class ThemedHtml extends StatelessWidget {
  final String html;

  const ThemedHtml(this.html, {super.key});

  @override
  Widget build(BuildContext context) => HtmlWidget(
    Theme.of(context).brightness == Brightness.dark ? adaptHtmlColorsForDarkTheme(html) : html,
    buildAsync: false,
  );
}

const _darkThemeColors = {'blue': '#64B5F6', 'green': '#81C784'};

final _colorAttribute = RegExp(r'''color=(['"])(\w+)\1''', caseSensitive: false);

/// Replaces the `color="…"` names in [html] that are too dark to read on a
/// dark background, leaving every other color (red, magenta, hex values)
/// untouched.
String adaptHtmlColorsForDarkTheme(String html) => html.replaceAllMapped(_colorAttribute, (match) {
  final replacement = _darkThemeColors[match[2]!.toLowerCase()];
  return replacement == null ? match[0]! : 'color=${match[1]}$replacement${match[1]}';
});
