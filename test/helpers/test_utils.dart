import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_starter/core/helpers/router/navigation_helper.dart';
import 'package:flutter_starter/core/services/di/locator.dart';
import 'package:flutter_starter/core/services/shared_preferences/service.dart';
import 'package:mocktail/mocktail.dart';

class MockSharedPreferencesService extends Mock implements SharedPreferencesService {}

class MockNavigationHelper extends Mock implements NavigationHelper {}

Future<void> setupTestLocator({
  SharedPreferencesService? sharedPreferencesService,
  NavigationHelper? navigationHelper,
}) async {
  await dotenv.load();

  if (!locator.isRegistered<SharedPreferencesService>()) {
    locator.registerSingleton<SharedPreferencesService>(
      sharedPreferencesService ?? MockSharedPreferencesService(),
    );
  }

  if (!locator.isRegistered<NavigationHelper>()) {
    locator.registerSingleton<NavigationHelper>(
      navigationHelper ?? MockNavigationHelper(),
    );
  }
}

void teardownTestLocator() {
  if (locator.isRegistered<SharedPreferencesService>()) {
    locator.unregister<SharedPreferencesService>();
  }
  if (locator.isRegistered<NavigationHelper>()) {
    locator.unregister<NavigationHelper>();
  }
}
