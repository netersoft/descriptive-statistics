import 'package:descriptive_statistics/core/services/i18n/translations.g.dart';
import 'package:descriptive_statistics/view/screens/calculators/discrete_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_utils.dart';

void main() {
  late MockSharedPreferencesService mockPrefs;

  setUp(() async {
    mockPrefs = MockSharedPreferencesService();
    when(() => mockPrefs.getInt(any(), defaultValue: any(named: 'defaultValue'))).thenReturn(3);
    await setupTestLocator(sharedPreferencesService: mockPrefs);
  });

  tearDown(teardownTestLocator);

  testWidgets('DiscreteScreen keeps in-progress entry rows alive when its TabBarView page goes off-screen', (tester) async {
    // Mirrors HomeScreen's own TabBarView shape (6 tabs, Discrete at index 1)
    // closely enough that jumping to a distant tab actually pushes this page
    // outside TabBarView's cache extent: switching away and back used to
    // dispose DiscreteScreen (and its entry-row controllers) because it had
    // no AutomaticKeepAliveClientMixin.
    final tabController = TabController(length: 6, vsync: tester);
    addTearDown(tabController.dispose);

    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    tabController.index = 1;

    await tester.pumpWidget(
      ProviderScope(
        child: TranslationProvider(
          child: MaterialApp(
            home: Scaffold(
              body: TabBarView(
                controller: tabController,
                children: const [
                  Placeholder(),
                  DiscreteScreen(),
                  Placeholder(),
                  Placeholder(),
                  Placeholder(),
                  Placeholder(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ajouter une entrée'));
    await tester.pumpAndSettle();

    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(0), '7');
    await tester.enterText(textFields.at(1), '9');
    await tester.pump();

    tabController.animateTo(5);
    await tester.pumpAndSettle();
    tabController.animateTo(1);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, '7'), findsOneWidget);
    expect(find.widgetWithText(TextField, '9'), findsOneWidget);
  });
}
