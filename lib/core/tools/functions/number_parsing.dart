/// Parses [text] as a double, accepting either '.' or ',' as the decimal
/// separator.
///
/// Android's numeric keyboard shows ',' as the decimal key on fr/de/es/pt
/// locales (matching how those languages write decimals), but
/// `double.tryParse` only understands '.' -- without this, typing "3,5" the
/// way those keyboards invite is rejected as a syntax error.
double? parseDecimal(String text) => double.tryParse(text.trim().replaceAll(',', '.'));
