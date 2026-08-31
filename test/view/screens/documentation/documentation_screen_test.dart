import 'package:flutter/material.dart';
import 'package:flutter_starter/core/services/i18n/translations.g.dart';
import 'package:flutter_starter/view/screens/documentation/documentation_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DocumentationScreen renders the localized course content', (tester) async {
    await tester.pumpWidget(
      TranslationProvider(
        child: const MaterialApp(home: DocumentationScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final rendered = tester.widgetList<RichText>(find.byType(RichText)).map((w) => w.text.toPlainText()).join('\n');

    expect(rendered, contains('Sommaire'));
    expect(rendered, contains('La statistique descriptive'));
  });
}
