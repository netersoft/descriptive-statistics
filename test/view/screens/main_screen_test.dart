import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter/core/providers/main/home_provider.dart';
import 'package:flutter_starter/core/routes/router.dart';
import 'package:flutter_starter/core/services/i18n/translations.g.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_utils.dart';

void main() {
  late MockSharedPreferencesService mockPrefs;

  setUp(() async {
    mockPrefs = MockSharedPreferencesService();
    when(() => mockPrefs.getInt(any(), defaultValue: any(named: 'defaultValue'))).thenReturn(3);
    await setupTestLocator(sharedPreferencesService: mockPrefs);
  });

  tearDown(teardownTestLocator);

  /// Pumps the real main screen, on the Discrete tab, with its first Xi
  /// field focused (keyboard up).
  Future<FocusNode> pumpWithFocusedField(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = createRouter(initialLocation: '/main', observers: []);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        // Start on the Discrete tab: the Course tab (the default) shows a
        // spinner while its HTML loads, which pumpAndSettle can't wait out.
        overrides: [homeProvider.overrideWith(_StartOnDiscreteTab.new)],
        child: TranslationProvider(child: MaterialApp.router(routerConfig: router)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ajouter une entrée'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField).first);
    await tester.pumpAndSettle();

    final focusNode = tester.widget<EditableText>(find.byType(EditableText).first).focusNode;
    expect(focusNode.hasFocus, isTrue);
    return focusNode;
  }

  testWidgets('switching tabs releases the focus of a field on the previous tab', (tester) async {
    final focusNode = await pumpWithFocusedField(tester);

    await tester.tap(find.text('Var. continues'));
    await tester.pumpAndSettle();

    expect(focusNode.hasFocus, isFalse);
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('coming back from Settings does not refocus the field (and reopen the keyboard)', (tester) async {
    final focusNode = await pumpWithFocusedField(tester);

    await tester.tap(find.byTooltip('Paramètres'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back_ios));
    await tester.pumpAndSettle();

    expect(find.text('Var. discrètes'), findsOneWidget);
    expect(focusNode.hasFocus, isFalse);
    expect(tester.testTextInput.isVisible, isFalse);
  });
}

class _StartOnDiscreteTab extends Home {
  @override
  int build() => 1;
}
