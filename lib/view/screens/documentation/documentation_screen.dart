import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

import '../../../core/services/i18n/translations.g.dart';
import '../../themes/app_colors.dart';

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
      final theme = Theme.of(context);
      // The course HTML's own <style> block (background/link colors) is never
      // read by flutter_widget_from_html_core -- it only understands inline
      // `style=""` attributes and per-tag defaults. Plain text already tracks
      // the theme correctly via DefaultTextStyle, but every `<a href>` is
      // colored with colorScheme.primary, which this app pins to the brand's
      // dark onyx (#353839) for buttons/app bars -- invisible against the dark
      // scaffold. Swap that one color, scoped to this subtree, in dark mode.
      final content = theme.brightness == Brightness.dark
          ? Theme(
              data: theme.copyWith(colorScheme: theme.colorScheme.copyWith(primary: AppColors.skyBlue)),
              child: HtmlWidget(snapshot.data!, buildAsync: false),
            )
          : HtmlWidget(snapshot.data!, buildAsync: false);
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: content,
      );
    },
  );
}
