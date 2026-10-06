import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/i18n/translations.g.dart';
import '../../themes/app_theme.dart';

/// The privacy policy, bundled with the app so it reads offline.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      elevation: 0.0,
      title: Text(context.t.privacyPolicy, style: const TextStyle(color: Colors.white)),
      backgroundColor: AppTheme.getAppbarBgColor(),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: () => context.pop(),
      ),
    ),
    body: FutureBuilder<String>(
      future: rootBundle.loadString('assets/docs/${LocaleSettings.currentLocale.languageCode}/privacy_policy.html'),
      builder: (context, snapshot) => switch (snapshot.data) {
        final html? => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: HtmlWidget(
            html,
            textStyle: Theme.of(context).textTheme.bodyMedium,
            onTapUrl: (url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
          ),
        ),
        null => const Center(child: CircularProgressIndicator()),
      },
    ),
  );
}
