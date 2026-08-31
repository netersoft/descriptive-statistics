import 'package:another_flutter_splash_screen/another_flutter_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/navigation/redirection_provider.dart';
import 'themes/app_colors.dart';
import 'themes/app_theme.dart';

/// Redirection screen
class Redirection extends ConsumerStatefulWidget {
  const Redirection({super.key});

  @override
  RedirectionState createState() => RedirectionState();
}

class RedirectionState extends ConsumerState<Redirection> {
  @override
  void initState() {
    super.initState();

    FlutterNativeSplash.remove();
  }

  /// Builds a FlutterSplashScreen widget showing the app icon for a fixed
  /// duration before handing off to [redirectionProvider.redirect] -- the
  /// native splash (see android12splash/launch_background) already covers
  /// the engine startup gap, so this is purely a short branded beat, not
  /// a loading indicator.
  @override
  Widget build(BuildContext context) {
    ref.watch(redirectionProvider);

    return FlutterSplashScreen(
      useImmersiveMode: true,
      duration: const Duration(milliseconds: 2000),
      backgroundColor: AppTheme.pickColor(
        light: AppTheme.primaryColor,
        dark: AppColors.raisinBlack,
      ),
      splashScreenBody: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.asset('assets/images/launcher/icon.png', width: 160, height: 160),
        ),
      ),
      onInit: () {},
      onEnd: () {
        ref.read(redirectionProvider.notifier).redirect(ref);
      },
    );
  }
}
