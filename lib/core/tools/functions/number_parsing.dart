/// Parses [text] as a double, accepting either '.' or ',' as the decimal
/// separator.
///
/// Android's numeric keyboard shows ',' as the decimal key on fr/de/es/pt
/// locales (matching how those languages write decimals), but
/// `double.tryParse` only understands '.' -- without this, typing "3,5" the
/// way those keyboards invite is rejected as a syntax error.
double? parseDecimal(String text) => double.tryParse(text.trim().replaceAll(',', '.'));

/// The decimal separator conventionally used to display numbers for
/// [languageCode]: ',' for fr/de/es/pt, '.' for English. Input already
/// accepts either separator via [parseDecimal]; this controls what's shown
/// back to the user, so results match the convention they typed in.
String decimalSeparatorForLocale(String languageCode) => languageCode == 'en' ? '.' : ',';
