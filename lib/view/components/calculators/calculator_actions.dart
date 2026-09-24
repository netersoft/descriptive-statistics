import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/data/backups/backups_repository.dart';
import '../../../core/models/backup_model.dart';
import '../../../core/providers/calculators/calculator_types.dart';
import '../../../core/services/di/locator.dart';
import '../../../core/services/i18n/translations.g.dart';

/// Shows why a calculation failed in a snackbar, when [error] is set.
void showCalculationError(BuildContext context, CalculationError? error) {
  if (error == null) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(calculationErrorMessage(context, error))));
}

String calculationErrorMessage(BuildContext context, CalculationError error) => switch (error) {
  CalculationError.insufficientData => context.t.insufficientData,
  CalculationError.emptyField => context.t.emptyFieldError,
  CalculationError.syntaxError => context.t.syntaxError,
  CalculationError.invalidValue => context.t.invalidValueError,
  CalculationError.overlappingClasses => context.t.overlappingClassesError,
};

/// Checkbox label for the options shared by the Discrete and Continuous
/// screens.
String statOptionLabel(BuildContext context, StatOption option) => switch (option) {
  StatOption.mean => context.t.meanCheckbox,
  StatOption.median => context.t.medianCheckbox,
  StatOption.quartiles => context.t.quartilesCheckbox,
  StatOption.mode => context.t.modeCheckbox,
  StatOption.variance => context.t.varianceCheckbox,
  StatOption.covariance => context.t.covarianceCheckbox,
  StatOption.standardDeviation => context.t.standardDeviationCheckbox,
  StatOption.coefficientOfVariation => context.t.coefficientOfVariationCheckbox,
  StatOption.charts => context.t.chartsCheckbox,
};

String qualitativeStatOptionLabel(BuildContext context, QualitativeStatOption option) => switch (option) {
  QualitativeStatOption.mean => context.t.meanCheckbox,
  QualitativeStatOption.mode => context.t.modeCheckbox,
  QualitativeStatOption.charts => context.t.chartsCheckbox,
};

/// "dd.MM.yyyy - HH:mm", the date format backups are stored with.
String formatBackupDate(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}.${two(date.month)}.${date.year} - ${two(date.hour)}:${two(date.minute)}';
}

/// Asks the user to name the study, then saves it as a [Backup] and
/// confirms with a snackbar. Does nothing if the user cancels.
Future<void> saveCalculationBackup(
  BuildContext context, {
  required String resolutionHtml,
  required String xi,
  required String ni,
}) async {
  final name = await _promptForStudyName(context);
  if (name == null) return;

  await locator<BackupsRepository>().add(
    Backup(name: name, resolutionHtml: resolutionHtml, xi: xi, ni: ni, date: formatBackupDate(DateTime.now())),
  );

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t.safeguardDone)));
  }
}

Future<String?> _promptForStudyName(BuildContext context) => showDialog<String>(
  context: context,
  builder: (dialogContext) {
    final controller = TextEditingController();
    return AlertDialog(
      title: Text(context.t.saveStats),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(hintText: context.t.statsName),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(context.t.cancel)),
        TextButton(
          onPressed: () {
            final name = controller.text.trim();
            if (name.isEmpty) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(context.t.namedThisStats)));
              return;
            }
            Navigator.of(dialogContext).pop(name);
          },
          child: Text(context.t.save),
        ),
      ],
    );
  },
);

/// Opens the system share sheet with a calculation summary.
Future<void> shareCalculationText(BuildContext context, String text) async {
  final box = context.findRenderObject() as RenderBox?;
  await SharePlus.instance.share(
    ShareParams(
      text: text,
      sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    ),
  );
}
