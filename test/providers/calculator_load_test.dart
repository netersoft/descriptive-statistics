import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter/core/providers/calculators/calculator_types.dart';
import 'package:flutter_starter/core/providers/calculators/continuous_provider.dart';
import 'package:flutter_starter/core/providers/calculators/discrete_provider.dart';
import 'package:flutter_starter/core/providers/calculators/qualitative_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_utils.dart';

void main() {
  late ProviderContainer container;

  setUp(() async {
    final mockPrefs = MockSharedPreferencesService();
    when(() => mockPrefs.getInt(any(), defaultValue: any(named: 'defaultValue'))).thenReturn(3);
    await setupTestLocator(sharedPreferencesService: mockPrefs);
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
    teardownTestLocator();
  });

  test('discrete load replaces the rows and stats, then computes', () {
    final notifier = container.read(discreteCalculatorProvider.notifier)..toggleShowCalculations();
    const rows = [
      ['1', '2'],
      ['2,5', '4'],
    ];

    expect(notifier.load(rows, {StatOption.mean}), isNull);

    final state = container.read(discreteCalculatorProvider);
    expect(state.loadedRows, rows);
    expect(state.loadCount, 1);
    expect(state.selectedStats, {StatOption.mean});
    expect(state.showCalculations, isTrue);
    expect(state.result!.xi, [1, 2.5]);
    expect(state.result!.ni, [2, 4]);
  });

  test('a load that fails does not keep the previous result', () {
    final notifier = container.read(discreteCalculatorProvider.notifier)..calculate(['1', '2'], ['2', '4']);
    expect(container.read(discreteCalculatorProvider).result, isNotNull);

    expect(
      notifier.load(const [
        ['1', '2'],
      ], StatOption.values.toSet()),
      CalculationError.insufficientData,
    );
    expect(container.read(discreteCalculatorProvider).result, isNull);
  });

  test('continuous load computes from the class bounds', () {
    container
        .read(continuousCalculatorProvider.notifier)
        .load(
          const [
            ['0', '10', '5'],
            ['10', '20', '8'],
          ],
          {StatOption.median},
        );

    final state = container.read(continuousCalculatorProvider);
    expect(state.l1, [0, 10]);
    expect(state.l2, [10, 20]);
    expect(state.result!.ni, [5, 8]);
    expect(state.loadCount, 1);
  });

  test('qualitative load computes from the modalities', () {
    container
        .read(qualitativeCalculatorProvider.notifier)
        .load(
          const [
            ['Rouge', '3'],
            ['Bleu', '5'],
          ],
          {QualitativeStatOption.mode},
        );

    final state = container.read(qualitativeCalculatorProvider);
    expect(state.result!.modalities, ['Rouge', 'Bleu']);
    expect(state.selectedStats, {QualitativeStatOption.mode});
  });
}
