import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/i18n/translations.g.dart';
import '../../components/misc/themed_html.dart';

/// Renders the localized descriptive-statistics course, ported as static
/// HTML from the legacy app's `assets/course_<locale>.html` -- mirrors
/// DocumentationFragment, which just pointed a WebView at that same file.
class DocumentationScreen extends StatelessWidget {
  const DocumentationScreen({super.key});

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
    future: rootBundle.loadString('assets/docs/${LocaleSettings.currentLocale.languageCode}/course.html'),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(child: Text(context.t.anErrorOccurred));
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ThemedHtml(snapshot.data!),
      );
    },
  );
}
