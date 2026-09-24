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
