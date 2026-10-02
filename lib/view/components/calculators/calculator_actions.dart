import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/data/backups/backup_data.dart';
import '../../../core/data/backups/backups_repository.dart';
import '../../../core/models/backup_model.dart';
import '../../../core/providers/calculators/calculator_types.dart';
import '../../../core/services/di/locator.dart';
import '../../../core/services/i18n/translations.g.dart';
import '../pdf/calculation_pdf.dart';

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
  CalculationError.invalidClassWidth => context.t.invalidClassWidthError,
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
/// confirms with a snackbar. Does nothing if the user cancels. [data] lets
/// the Backups screen recompute the calculation (and so show it in the
/// current language); [resolutionHtml], [xi] and [ni] keep the fields older
/// app versions rely on filled in.
Future<void> saveCalculationBackup(
  BuildContext context, {
  required BackupData data,
  required String resolutionHtml,
  required String xi,
  required String ni,
}) async {
  final name = await _promptForStudyName(context);
  if (name == null) return;

  final now = DateTime.now();
  await locator<BackupsRepository>().add(
    Backup(
      name: name,
      resolutionHtml: resolutionHtml,
      xi: xi,
      ni: ni,
      date: formatBackupDate(now),
      kind: data.kind.name,
      data: data.encode(),
      createdAt: now,
    ),
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

/// Builds the calculation's PDF (see [buildCalculationPdf]) and opens the
/// system share sheet with it, named after [title].
Future<void> shareCalculationPdf(
  BuildContext context, {
  required String title,
  required String dateLabel,
  required BackupData? data,
  required String fallbackHtml,
  required PdfChartTypes chartTypes,
}) async {
  final bytes = await buildCalculationPdf(
    title: title,
    dateLabel: dateLabel,
    data: data,
    fallbackHtml: fallbackHtml,
    chartTypes: chartTypes,
  );
  final dir = await Directory.systemTemp.createTemp('statistique_descriptive_pdf');
  final file = File('${dir.path}/${pdfFileName(title)}');
  await file.writeAsBytes(bytes);
  if (!context.mounted) return;

  final box = context.findRenderObject() as RenderBox?;
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'application/pdf')],
      sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    ),
  );
}

/// [title] as a file name: characters that file systems or share targets
/// may reject become "_".
String pdfFileName(String title) {
  final safe = title.trim().replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '_');
  return '${safe.isEmpty ? 'statistique_descriptive' : safe}.pdf';
}
