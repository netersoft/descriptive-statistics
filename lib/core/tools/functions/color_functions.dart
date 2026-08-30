import 'dart:ui';

/// Determine if a color is dark
bool isColorDark(Color color) {
  double luminance = 0.299 * color.r + 0.587 * color.g + 0.114 * color.b;
  return luminance < 0.5;
}
