import 'package:flutter/material.dart';
import 'package:flutter_starter/core/providers/calculators/calculator_types.dart';
import 'package:flutter_starter/core/services/i18n/translations.g.dart';
import 'package:flutter_starter/core/stats/stats_exceptions.dart';
import 'package:flutter_starter/view/components/calculators/calculator_actions.dart';
import 'package:flutter_starter/view/components/calculators/calculator_form.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EntryRows', () {
    late EntryRows rows;

    setUp(() => rows = EntryRows(2));
    tearDown(() => rows.dispose());

    test('adds empty or prefilled rows and reads them back column by column', () {
      rows
        ..add()
        ..add(['3', '4']);
      rows[0][0].text = '1';
      rows[0][1].text = '2';

      expect(rows.length, 2);
      expect(rows.column(0), ['1', '3']);
      expect(rows.column(1), ['2', '4']);
    });

    test('removes a row', () {
      rows
        ..add(['1', '2'])
        ..add(['3', '4'])
        ..removeAt(0);

      expect(rows.column(0), ['3']);
    });

    test('imports pasted rows after dropping fully blank ones, keeping partially filled ones', () {
      rows
        ..add()
        ..add(['5', ''])
        ..add([' ', ''])
        ..importRows([
          ['1', '2'],
          ['3', '4'],
        ]);

      expect(rows.column(0), ['5', '1', '3']);
      expect(rows.column(1), ['', '2', '4']);
    });
  });

  group('EntryRows change tracking', () {
    test('hasText ignores rows holding only blanks', () {
      final rows = EntryRows(2)..add(['', ' ']);
      addTearDown(rows.dispose);

      expect(rows.hasText, isFalse);
      rows[0][1].text = '3';
      expect(rows.hasText, isTrue);
    });

    test('reports user changes, but not replaceRows', () {
      var changes = 0;
      final rows = EntryRows(2, onChanged: () => changes++);
      addTearDown(rows.dispose);

      rows.add();
      expect(changes, 1);
      rows[0][0].text = '1';
      expect(changes, 2);
      rows.importRows([
        ['2', '3'],
      ]);
      expect(changes, 3);
      rows.removeAt(0);
      expect(changes, 4);

      rows.replaceRows([
        ['4', '5'],
      ]);
      expect(changes, 4);
      expect(rows.column(0), ['4']);
    });
  });

  group('StatOptionsChecklist', () {
    Future<void> pump(WidgetTester tester, Set<QualitativeStatOption> selected, {void Function(bool)? onToggleAll}) => tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: Scaffold(
            body: StatOptionsChecklist<QualitativeStatOption>(
              options: QualitativeStatOption.values,
              selected: selected,
              label: (option) => option.name,
              expanded: true,
              onHeaderTap: () {},
              onToggleAll: onToggleAll ?? (_) {},
              onToggle: (_, _) {},
            ),
          ),
        ),
      ),
    );

    bool selectAllValue(WidgetTester tester) => tester.widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, 'Tout sélectionner')).value!;

    testWidgets('checks "select all" only when every option is selected', (tester) async {
      await pump(tester, QualitativeStatOption.values.toSet());
      expect(selectAllValue(tester), isTrue);

      await pump(tester, {QualitativeStatOption.mean});
      expect(selectAllValue(tester), isFalse);
    });

    testWidgets('reports the "select all" toggle', (tester) async {
      bool? toggled;
      await pump(tester, {}, onToggleAll: (value) => toggled = value);

      await tester.tap(find.text('Tout sélectionner'));

      expect(toggled, isTrue);
    });
  });

  test('formatBackupDate uses the stored dd.MM.yyyy - HH:mm format', () {
    expect(formatBackupDate(DateTime(2026, 3, 7, 9, 5)), '07.03.2026 - 09:05');
  });

  test('calculationErrorFor maps every engine rejection to a user-facing error', () {
    expect(calculationErrorFor(StatsErrorReason.insufficientData), CalculationError.insufficientData);
    expect(calculationErrorFor(StatsErrorReason.negativeEffectif), CalculationError.invalidValue);
    expect(calculationErrorFor(StatsErrorReason.zeroTotalEffectif), CalculationError.invalidValue);
    expect(calculationErrorFor(StatsErrorReason.invalidClassWidth), CalculationError.invalidClassWidth);
    expect(calculationErrorFor(StatsErrorReason.overlappingClasses), CalculationError.overlappingClasses);
    expect(calculationErrorFor(StatsErrorReason.lengthMismatch), CalculationError.syntaxError);
  });
}
