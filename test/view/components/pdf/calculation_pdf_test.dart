import 'dart:convert';

import 'package:descriptive_statistics/core/data/backups/backup_data.dart';
import 'package:descriptive_statistics/core/providers/calculators/calculator_types.dart';
import 'package:descriptive_statistics/core/tools/constants/chart_options.dart';
import 'package:descriptive_statistics/view/components/calculators/calculator_actions.dart';
import 'package:descriptive_statistics/view/components/pdf/calculation_pdf.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await dotenv.load();
  });

  final allCharts = (
    discrete: QuantitativeChartType.values.toSet(),
    continuous: QuantitativeChartType.values.toSet(),
    qualitative: QualitativeChartType.values.toSet(),
  );
  final allStats = [for (final option in StatOption.values) option.name];

  Future<String> pdfHeader(BackupData? data, {String fallbackHtml = ''}) async {
    final bytes = await buildCalculationPdf(
      title: 'Étude',
      dateLabel: '02/10/2026 08:40',
      data: data,
      fallbackHtml: fallbackHtml,
      chartTypes: allCharts,
    );
    return latin1.decode(bytes.take(5).toList());
  }

  group('buildCalculationPdf', () {
    test('builds a PDF for each calculator, with every stat and chart', () async {
      final cases = [
        BackupData(
          kind: BackupKind.discrete,
          columns: const [
            [1, 2, 3],
            [2, 4, 6],
          ],
          selectedStats: allStats,
          precision: 3,
        ),
        // Unequal widths: charts plot densities, with a note.
        BackupData(
          kind: BackupKind.continuous,
          columns: const [
            [0, 10, 20],
            [10, 20, 40],
            [5, 8, 4],
          ],
          selectedStats: allStats,
          precision: 3,
        ),
        BackupData(
          kind: BackupKind.qualitative,
          columns: const [
            ['A', 'B'],
            [3, 1],
          ],
          selectedStats: [for (final option in QualitativeStatOption.values) option.name],
          precision: 3,
        ),
      ];
      for (final data in cases) {
        expect(await pdfHeader(data), '%PDF-', reason: data.kind.name);
      }
    });

    test('falls back to the stored explanation for a backup saved before 1.6', () async {
      expect(await pdfHeader(null, fallbackHtml: '<b>MOYENNE</b><br>X = 3'), '%PDF-');
    });

    test('still builds one when the data no longer computes', () async {
      final broken = BackupData(
        kind: BackupKind.discrete,
        columns: const [
          [1],
          [2],
        ],
        selectedStats: allStats,
        precision: 3,
      );
      expect(await pdfHeader(broken, fallbackHtml: 'X = 3'), '%PDF-');
    });
  });

  test('pdfFileName replaces the characters file systems reject', () {
    expect(pdfFileName('Notes 2/3: "maths"'), 'Notes 2_3_ _maths_.pdf');
    expect(pdfFileName('  '), 'statistique_descriptive.pdf');
  });
}
