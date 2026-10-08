import 'dart:async';

import 'package:descriptive_statistics/core/providers/main/home_provider.dart';
import 'package:descriptive_statistics/core/routes/router.dart';
import 'package:descriptive_statistics/core/services/i18n/translations.g.dart';
import 'package:descriptive_statistics/view/screens/course/course_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_utils.dart';

void main() {
  setUp(() async {
    final prefs = MockSharedPreferencesService();
    when(() => prefs.getInt(any(), defaultValue: any(named: 'defaultValue'))).thenReturn(3);
    await setupTestLocator(sharedPreferencesService: prefs);
  });

  tearDown(teardownTestLocator);

  /// A tall screen, so that the lazily built lists show every topic.
  void useTallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> pumpCourseTab(WidgetTester tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(
      ProviderScope(
        child: TranslationProvider(
          child: const MaterialApp(home: Scaffold(body: CourseScreen())),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('CourseScreen', () {
    testWidgets('lists the topics by section', (tester) async {
      await pumpCourseTab(tester);

      expect(find.text('VOCABULAIRE'), findsOneWidget);
      expect(find.text('PARAMÈTRES DE DISPERSION'), findsOneWidget);
      expect(find.text('La statistique descriptive'), findsOneWidget);
      expect(find.text("L'écart type"), findsOneWidget);
    });

    testWidgets('search ignores case and accents', (tester) async {
      await pumpCourseTab(tester);

      await tester.enterText(find.byType(TextField), 'ECART');
      await tester.pumpAndSettle();

      expect(find.text("L'écart type"), findsOneWidget);
      expect(find.text('La statistique descriptive'), findsNothing);
      expect(find.text('VOCABULAIRE'), findsNothing);
    });

    testWidgets('says so when nothing matches, and the clear button restores the list', (tester) async {
      await pumpCourseTab(tester);

      await tester.enterText(find.byType(TextField), 'xyzzy');
      await tester.pumpAndSettle();
      expect(find.text('Aucune notion ne correspond à « xyzzy »'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('La statistique descriptive'), findsOneWidget);
    });

    testWidgets('shows the course in the new language when the language changes', (tester) async {
      await pumpCourseTab(tester);
      expect(find.text('VOCABULAIRE'), findsOneWidget);

      // Non-base locales are deferred imports, loaded outside the fake
      // async zone (see tutorial_screen_test.dart).
      await tester.runAsync(() => LocaleSettings.setLocaleRaw('de'));
      addTearDown(() => LocaleSettings.setLocaleRaw('fr'));
      await tester.pumpAndSettle();

      expect(find.text('GRUNDBEGRIFFE'), findsOneWidget);
      expect(find.text('VOCABULAIRE'), findsNothing);
    });
  });

  group('CourseTopicScreen', () {
    Future<(GoRouter, ProviderContainer)> pumpTopic(WidgetTester tester, String topicId) async {
      useTallScreen(tester);
      final router = createRouter(initialLocation: '/main', observers: []);
      addTearDown(router.dispose);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: TranslationProvider(child: MaterialApp.router(routerConfig: router)),
        ),
      );
      await tester.pumpAndSettle();
      unawaited(router.push('/main/course/$topicId'));
      await tester.pumpAndSettle();
      return (router, container);
    }

    testWidgets('shows the definition, the formulas and their symbols', (tester) async {
      await pumpTopic(tester, 'median');

      expect(find.text('La médiane'), findsOneWidget);
      expect(find.text('VARIABLE DISCRÈTE'), findsOneWidget);
      expect(find.text('VARIABLE CONTINUE'), findsOneWidget);
      expect(find.text('Borne inférieure de la classe médiane'), findsOneWidget);
      expect(find.byType(Math), findsWidgets);
    });

    testWidgets('the calculator button goes back to the matching calculator tab', (tester) async {
      final (router, container) = await pumpTopic(tester, 'median');

      await tester.tap(find.text('Calculer une série continue'));
      await tester.pumpAndSettle();

      expect(container.read(homeProvider), HomeTab.continuous);
      expect(router.location, '/main');
    });

    testWidgets('the next link replaces the topic, so Back returns to the list', (tester) async {
      final (router, _) = await pumpTopic(tester, 'median');

      await tester.tap(find.text('Le mode'));
      await tester.pumpAndSettle();
      expect(router.location, '/main/course/mode');
      expect(find.text('Variable discrète'.toUpperCase()), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();
      expect(router.location, '/main');
    });

    testWidgets('the first topic has no previous link', (tester) async {
      await pumpTopic(tester, 'descriptive-statistics');

      expect(find.textContaining('précédent'), findsNothing);
      expect(find.textContaining('suivant'), findsOneWidget);
    });
  });
}
