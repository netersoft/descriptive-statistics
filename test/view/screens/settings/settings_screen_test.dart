import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter/core/services/i18n/translations.g.dart';
import 'package:flutter_starter/core/services/shared_preferences/keys.dart';
import 'package:flutter_starter/view/screens/settings/settings_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_utils.dart';

void main() {
  late MockSharedPreferencesService mockPrefs;
  late MockNavigationHelper mockNav;

  setUp(() async {
    mockPrefs = MockSharedPreferencesService();
    mockNav = MockNavigationHelper();
    when(() => mockPrefs.getInt(any(), defaultValue: any(named: 'defaultValue'))).thenReturn(3);
    when(() => mockPrefs.getString(any(), defaultValue: any(named: 'defaultValue'))).thenReturn('system');
    when(() => mockPrefs.setInt(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.getListString(any())).thenReturn(null);
    when(() => mockPrefs.setStringList(any(), any())).thenAnswer((_) async => true);
    await setupTestLocator(sharedPreferencesService: mockPrefs, navigationHelper: mockNav);
  });

  tearDown(teardownTestLocator);

  testWidgets('changing the number of decimals persists the new value', (tester) async {
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (context, state) => const SettingsScreen())],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        child: TranslationProvider(
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('3'), findsOneWidget);

    await tester.tap(find.text('Nombre de décimales'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();

    verify(() => mockPrefs.setInt(PrefKeys.decimalPrecision, 5)).called(1);
    verify(() => mockNav.go(any())).called(1);
  });

  testWidgets('unchecking a discrete chart type persists the remaining selection', (tester) async {
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (context, state) => const SettingsScreen())],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        child: TranslationProvider(
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Variables quantitatives discrètes'));
    await tester.pumpAndSettle();

    // Both chart types are checked by default (no stored preference).
    expect(find.byType(CheckboxListTile), findsNWidgets(2));
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Lignes'));
    await tester.pumpAndSettle();

    verify(() => mockPrefs.setStringList(PrefKeys.discreteChartTypes, ['bar'])).called(1);
  });
}
