import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_starter/core/services/i18n/translations.g.dart';
import 'package:flutter_starter/view/components/calculators/chart_carousel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    await dotenv.load();
  });

  testWidgets('tells the user no chart type is selected instead of rendering an empty gap', (tester) async {
    await tester.pumpWidget(
      TranslationProvider(
        child: const MaterialApp(home: ChartCarousel(charts: [])),
      ),
    );

    expect(find.byType(PageView), findsNothing);
    expect(find.text('Aucun type de graphique sélectionné. Modifiez ce choix dans les Réglages.'), findsOneWidget);
  });

  testWidgets('pages between charts with the next/prev arrows', (tester) async {
    await tester.pumpWidget(
      TranslationProvider(
        child: const MaterialApp(
          home: ChartCarousel(
            charts: [
              Text('Chart A'),
              Text('Chart B'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chart A'), findsOneWidget);
    expect(find.text('Chart B'), findsNothing);

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();

    expect(find.text('Chart A'), findsNothing);
    expect(find.text('Chart B'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    expect(find.text('Chart A'), findsOneWidget);
  });

  testWidgets('box plot lists its five values', (tester) async {
    await tester.pumpWidget(
      TranslationProvider(
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 240,
              child: BoxPlotChart(summary: (min: 1, q1: 2, median: 3.5, q3: 4, max: 6)),
            ),
          ),
        ),
      ),
    );

    for (final label in ['Min = 1', 'Q1 = 2', 'Me = 3,5', 'Q3 = 4', 'Max = 6']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  group('axisTicks', () {
    test('spans the values with a 1, 2 or 5 ×10^k step', () {
      expect(axisTicks(1, 6), [1, 2, 3, 4, 5, 6]);
      expect(axisTicks(0, 40), [0, 10, 20, 30, 40]);
      expect(axisTicks(3, 97), [0, 20, 40, 60, 80, 100]);
      expect(axisTicks(-2, 7), [-2, 0, 2, 4, 6, 8]);
    });

    test('keeps decimal steps free of floating-point drift', () {
      expect(axisTicks(0.1, 0.9), [0, 0.2, 0.4, 0.6, 0.8, 1]);
      expect(axisTicks(0.03, 0.27), [0, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3]);
    });

    test('gives a single tick when every value is equal', () {
      expect(axisTicks(5, 5), [5]);
    });
  });

  group('roundedPercentages', () {
    test('adds up to exactly 100 where rounding each share separately would not', () {
      // 62.5 % and 37.5 % would each round up to 63 % + 38 % = 101 %.
      expect(roundedPercentages([5, 3]), [63, 37]);
      // Three thirds would each round down to 33 % -> 99 %.
      expect(roundedPercentages([1, 1, 1]), [34, 33, 33]);
    });

    test('keeps exact shares unchanged', () {
      expect(roundedPercentages([1, 3]), [25, 75]);
    });

    test('always sums to 100 for arbitrary values', () {
      for (final values in <List<double>>[
        [7.0, 11, 13, 17, 19],
        [0.1, 0.2, 0.3],
        [1.0, 0, 2],
        [3.0, 3, 3, 3, 3, 3, 3],
      ]) {
        expect(roundedPercentages(values).reduce((a, b) => a + b), 100, reason: '$values');
      }
    });

    test('is empty when the values sum to zero', () {
      expect(roundedPercentages([0, 0]), isEmpty);
    });
  });
}
