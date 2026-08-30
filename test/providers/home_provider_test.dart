import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter/core/providers/main/home_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomeProvider', () {
    test('initial state is tab index 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(homeProvider), 0);
    });

    test('tabIndex setter updates the current tab index', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final home = container.read(homeProvider.notifier)..tabIndex = 3;
      expect(container.read(homeProvider), 3);

      home.tabIndex = 0;
      expect(container.read(homeProvider), 0);
    });
  });
}
