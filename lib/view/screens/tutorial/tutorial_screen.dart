import 'package:flutter/material.dart';

import '../../../core/services/i18n/translations.g.dart';
import '../../components/tutorial/tutorial_steps.dart';

/// Permanent "how to proceed" walkthrough, always reachable from the
/// drawer -- shows the same 4 steps as the first-run [IntroScreen].
class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final steps = tutorialSteps(LocaleSettings.currentLocale.languageCode);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            context.t.howToProceed,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          for (final step in steps) TutorialStepCard(step: step),
        ],
      ),
    );
  }
}
