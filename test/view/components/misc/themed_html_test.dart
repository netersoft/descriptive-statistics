import 'package:descriptive_statistics/view/components/misc/themed_html.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('adaptHtmlColorsForDarkTheme', () {
    test('lightens the blue and green font colors, whatever the quotes or case', () {
      expect(
        adaptHtmlColorsForDarkTheme("<font color='blue'>A</font><font color=\"GREEN\">B</font>"),
        "<font color='#64B5F6'>A</font><font color=\"#81C784\">B</font>",
      );
    });

    test('leaves colors that already read well on a dark background untouched', () {
      const html = "<font color='red'>A</font><font color='magenta'>B</font><font color='#123456'>C</font>";

      expect(adaptHtmlColorsForDarkTheme(html), html);
    });
  });

  group('ThemedHtml', () {
    Color? renderedColorOf(WidgetTester tester, String text) {
      Color? found;
      for (final richText in tester.widgetList<RichText>(find.byType(RichText))) {
        richText.text.visitChildren((span) {
          if (span is TextSpan && (span.text?.contains(text) ?? false)) {
            found = span.style?.color;
            return false;
          }
          return true;
        });
      }
      return found;
    }

    Future<void> pump(WidgetTester tester, Brightness brightness) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: const Scaffold(body: ThemedHtml("<font color='blue'>Titre</font>")),
        ),
      );
    }

    testWidgets('renders blue as-is on the light theme', (tester) async {
      await pump(tester, Brightness.light);

      expect(renderedColorOf(tester, 'Titre'), const Color(0xFF0000FF));
    });

    testWidgets('renders blue as a lighter tint on the dark theme', (tester) async {
      await pump(tester, Brightness.dark);

      expect(renderedColorOf(tester, 'Titre'), const Color(0xFF64B5F6));
    });
  });
}
