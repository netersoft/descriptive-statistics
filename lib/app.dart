import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/lifecycle/app_lifecycle_layer.dart';
import 'core/routes/router.dart';
import 'core/services/i18n/translations.g.dart';
import 'view/themes/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return const AppLifecycleLayer(child: AppRouterView());
  }
}

class AppRouterView extends ConsumerWidget {
  const AppRouterView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => TranslationProvider(
    child: Builder(
      builder: (context) => MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.setup(context),
        locale: TranslationProvider.of(context).flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: const [
          GlobalWidgetsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
        onGenerateTitle: (ctx) => t.appNameAlt,
      ),
    ),
  );
}
