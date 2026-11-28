abstract class PrefKeys {
  static const brightness = 'appBrightness';
  static const firstOpening = 'appFirstOpening';

  /// Set once the in-app review sheet was requested (see ReviewService).
  static const reviewRequested = 'reviewRequested';

  /// When the in-app review sheet was requested (ms since epoch), the store dialog waits after it.
  static const reviewRequestedAt = 'reviewRequestedAt';

  /// How many times the store dialog was shown, and when last (ms since epoch).
  static const rateDialogCount = 'rateDialogCount';
  static const rateDialogLastAt = 'rateDialogLastAt';

  /// The user rated, or asked not to be asked again.
  static const rateDone = 'rateDone';

  /// Language code picked in Settings; unset means "follow the device".
  static const language = 'appLanguage';

  /// Number of decimal places used when rounding calculator results.
  static const decimalPrecision = 'decimalPrecision';

  static const discreteChartTypes = 'discreteChartTypes';
  static const continuousChartTypes = 'continuousChartTypes';
  static const qualitativeChartTypes = 'qualitativeChartTypes';
}
