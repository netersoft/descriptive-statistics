import 'package:descriptive_statistics/core/services/i18n/translations.g.dart';
import 'package:descriptive_statistics/view/screens/documentation/documentation_screen.dart';
import 'package:flutter/material.dart';
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

  testWidgets('renders the German course content for the de locale', (tester) async {
    // Non-base locales are deferred imports; loadLibrary() under the hood
    // of setLocaleRaw needs a real async zone to resolve, same as Hive I/O
    // elsewhere in this suite -- without runAsync, pumpAndSettle hangs.
    await tester.runAsync(() => LocaleSettings.setLocaleRaw('de'));
    addTearDown(() => LocaleSettings.setLocaleRaw('fr'));

    await tester.pumpWidget(
      TranslationProvider(
        child: const MaterialApp(home: DocumentationScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final rendered = tester.widgetList<RichText>(find.byType(RichText)).map((w) => w.text.toPlainText()).join('\n');

    expect(rendered, contains('Inhaltsverzeichnis'));
  });
}
