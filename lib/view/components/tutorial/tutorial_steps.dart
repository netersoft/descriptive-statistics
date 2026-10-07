import 'package:flutter/material.dart';

import '../../../core/services/i18n/translations.g.dart';

/// One step of the "how to proceed" walkthrough -- mirrors the legacy
/// app's fragment_tutorial.xml, which showed the same 4 (text, screenshot)
/// cards both in the first-run intro flow and in the permanent Tutorial tab.
class TutorialStep {
  final String Function(Translations t) text;
  final String imageAsset;

  const TutorialStep({required this.text, required this.imageAsset});
}

const _supportedTutorialLocales = ['fr', 'en', 'de', 'es', 'pt'];

List<TutorialStep> tutorialSteps(String languageCode) {
  final locale = _supportedTutorialLocales.contains(languageCode) ? languageCode : 'en';
  return [
    TutorialStep(
      text: (t) => t.tutoStep1,
      imageAsset: 'assets/images/tutorial/$locale/tuto_1.png',
    ),
    TutorialStep(
      text: (t) => t.tutoStep2,
      imageAsset: 'assets/images/tutorial/$locale/tuto_2.png',
    ),
    TutorialStep(
      text: (t) => t.tutoStep3,
      imageAsset: 'assets/images/tutorial/$locale/tuto_3.png',
    ),
    TutorialStep(
      text: (t) => t.tutoStep4,
      imageAsset: 'assets/images/tutorial/$locale/tuto_4.png',
    ),
  ];
}

/// Renders one [TutorialStep] as a card (text label above a screenshot),
/// used both by [TutorialScreen] and [IntroScreen].
class TutorialStepCard extends StatelessWidget {
  final TutorialStep step;

  const TutorialStepCard({required this.step, super.key});

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(step.text(context.t), style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Image.asset(step.imageAsset),
        ],
      ),
    ),
  );
}
