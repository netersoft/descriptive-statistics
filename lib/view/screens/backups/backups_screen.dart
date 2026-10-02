import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/data/backups/backup_data.dart';
import '../../../core/data/backups/backups_json.dart';
import '../../../core/data/backups/backups_repository.dart';
import '../../../core/models/backup_model.dart';
import '../../../core/providers/settings/settings_provider.dart';
import '../../../core/services/di/locator.dart';
import '../../../core/services/i18n/translations.g.dart';
import '../../components/backups/backup_presentation.dart';
import '../../components/backups/load_backup.dart';
import '../../components/calculators/calculator_actions.dart';
import '../../components/calculators/chart_carousel.dart';
import '../../components/misc/themed_html.dart';
import '../../components/pdf/calculation_pdf.dart';

/// Lists saved calculation results (from the Discrete/Continuous/
/// Qualitative screens' Save action), expandable to show the stored
/// step-by-step resolution, with delete-by-confirmation -- mirrors the
/// legacy app's BackupsFragment/BackupsAdapter.
class BackupsScreen extends ConsumerStatefulWidget {
  const BackupsScreen({super.key});

  @override
  ConsumerState<BackupsScreen> createState() => _BackupsScreenState();
}

class _BackupsScreenState extends ConsumerState<BackupsScreen> {
  final _repository = locator<BackupsRepository>();
  final Set<dynamic> _expandedKeys = {};

  // Read once rather than in build(): Box.listenable() returns a new
  // wrapper on every call, so re-reading it on each rebuild would make
  // ValueListenableBuilder tear down and resubscribe every time this
  // widget rebuilds instead of just once for its whole lifetime.
  late final ValueListenable<Box<Backup>> _backups = _repository.watch();

  Future<void> _confirmDelete(dynamic key) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.t.deletionTitle),
        content: Text(context.t.deletionMsg),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(context.t.no)),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(context.t.yes)),
        ],
      ),
    );

    if (confirmed ?? false) {
      await _repository.deleteAt(key);
      _expandedKeys.remove(key);
    }
  }

  /// Writes all saved backups to a JSON file and hands it to the share
  /// sheet -- lets the user carry their calculations to another device or
  /// keep an external copy, since Hive's storage is local-only.
  Future<void> _export() async {
    final backups = _repository.readAll();
    if (backups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t.noSafeguard)));
      return;
    }

    final box = context.findRenderObject() as RenderBox?;
    final dir = await Directory.systemTemp.createTemp('statistique_descriptive_backups');
    final file = File('${dir.path}/statistique_descriptive_backups.json');
    await file.writeAsString(exportBackupsToJson(backups));

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  /// Lets the user pick a JSON file previously produced by [_export] and
  /// adds every backup it contains -- appended alongside whatever is
  /// already saved on this device, never replacing it.
  Future<void> _import() async {
    final picked = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['json']);
    final path = picked?.path;
    if (path == null) return;

    try {
      final backups = parseBackupsJson(await File(path).readAsString());
      for (final backup in backups) {
        await _repository.add(backup);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t.backupsImported)));
      }
    } on FormatException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t.backupsImportInvalidFormat)));
      }
    }
  }

  /// Shares the backup as a PDF; one saved before 1.6 only has its
  /// explanation (see [buildCalculationPdf]).
  Future<void> _exportPdf(Backup backup) => shareCalculationPdf(
    context,
    title: backup.name,
    dateLabel: backupDateLabel(backup, LocaleSettings.currentLocale.languageCode),
    data: BackupData.decode(backup.kind, backup.data),
    fallbackHtml: backup.resolutionHtml,
    chartTypes: pdfChartTypes(ref.read(settingsProvider)),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Wrap(
            children: [
              TextButton.icon(
                onPressed: _export,
                icon: const Icon(Icons.upload_outlined),
                label: Text(context.t.exportBackupsAction),
              ),
              TextButton.icon(
                onPressed: _import,
                icon: const Icon(Icons.download_outlined),
                label: Text(context.t.importBackupsAction),
              ),
            ],
          ),
        ),
        Expanded(
          child: ValueListenableBuilder<Box<Backup>>(
            valueListenable: _backups,
            builder: (context, box, _) {
              final keys = box.keys.toList();

              if (keys.isEmpty) {
                return Center(child: Text(context.t.noSafeguard));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: keys.length,
                itemBuilder: (context, index) {
                  final key = keys[index];
                  final backup = box.get(key)!;
                  final expanded = _expandedKeys.contains(key);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(backup.name),
                          subtitle: Text(backupDateLabel(backup, LocaleSettings.currentLocale.languageCode)),
                          onTap: () => setState(() {
                            if (expanded) {
                              _expandedKeys.remove(key);
                            } else {
                              _expandedKeys.add(key);
                            }
                          }),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: context.t.delete,
                            onPressed: () => _confirmDelete(key),
                          ),
                        ),
                        if (expanded) ...[
                          if (backupChartData(backup, LocaleSettings.currentLocale.languageCode) case (final labels, final values))
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: SizedBox(
                                height: 180,
                                child: qualitativeBarChart(labels: labels, values: values),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: ThemedHtml(backupExplanationHtml(backup)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                            child: Wrap(
                              alignment: WrapAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _exportPdf(backup),
                                  icon: const Icon(Icons.picture_as_pdf_outlined),
                                  label: Text(context.t.exportPdf),
                                ),
                                // Backups saved before 1.6 only kept their
                                // HTML, not the values needed to reload them.
                                if (BackupData.decode(backup.kind, backup.data) case final data?)
                                  TextButton.icon(
                                    onPressed: () => loadBackupIntoCalculator(context, ref, data),
                                    icon: const Icon(Icons.calculate_outlined),
                                    label: Text(context.t.loadBackupAction),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );
}
