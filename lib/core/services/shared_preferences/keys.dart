abstract class PrefKeys {
  static const brightness = 'appBrightness';
  static const firstOpening = 'appFirstOpening';

  /// Set once the in-app review sheet was requested (see ReviewService).
  static const reviewRequested = 'reviewRequested';

  /// Language code picked in Settings; unset means "follow the device".
  static const language = 'appLanguage';

  /// Number of decimal places used when rounding calculator results.
  static const decimalPrecision = 'decimalPrecision';

  static const discreteChartTypes = 'discreteChartTypes';
  static const continuousChartTypes = 'continuousChartTypes';
  static const qualitativeChartTypes = 'qualitativeChartTypes';
}
