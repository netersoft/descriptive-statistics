import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

import '../../../core/services/i18n/translations.g.dart';

/// Renders the localized descriptive-statistics course, ported as static
/// HTML from the legacy app's `assets/course_<locale>.html` -- mirrors
/// DocumentationFragment, which just pointed a WebView at that same file.
class DocumentationScreen extends StatelessWidget {
  const DocumentationScreen({super.key});

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
    future: rootBundle.loadString('assets/docs/${LocaleSettings.currentLocale.languageCode}/course.html'),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: HtmlWidget(snapshot.data!, buildAsync: false),
      );
    },
  );
}
