import 'package:descriptive_statistics/core/helpers/router/navigation_helper.dart';
import 'package:descriptive_statistics/core/services/di/locator.dart';
import 'package:descriptive_statistics/core/services/review/service.dart';
import 'package:descriptive_statistics/core/services/shared_preferences/service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mocktail/mocktail.dart';

class MockSharedPreferencesService extends Mock implements SharedPreferencesService {}

class MockNavigationHelper extends Mock implements NavigationHelper {}

class MockReviewService extends Mock implements ReviewService {}

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

  if (!locator.isRegistered<ReviewService>()) {
    final review = MockReviewService();
    when(review.requestOnce).thenAnswer((_) async {});
    locator.registerSingleton<ReviewService>(review);
  }

  if (!locator.isRegistered<NavigationHelper>()) {
    locator.registerSingleton<NavigationHelper>(
      navigationHelper ?? MockNavigationHelper(),
    );
  }
}

void teardownTestLocator() {
  if (locator.isRegistered<ReviewService>()) {
    locator.unregister<ReviewService>();
  }
  if (locator.isRegistered<SharedPreferencesService>()) {
    locator.unregister<SharedPreferencesService>();
  }
  if (locator.isRegistered<NavigationHelper>()) {
    locator.unregister<NavigationHelper>();
  }
}
