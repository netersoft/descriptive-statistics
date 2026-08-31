import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_starter/view/components/calculators/chart_carousel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    await dotenv.load();
  });

  testWidgets('renders nothing for an empty chart list', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ChartCarousel(charts: [])));

    expect(find.byType(ChartCarousel), findsOneWidget);
    expect(find.byType(PageView), findsNothing);
  });

  testWidgets('pages between charts with the next/prev arrows', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ChartCarousel(
          charts: [
            Text('Chart A'),
            Text('Chart B'),
          ],
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
}
