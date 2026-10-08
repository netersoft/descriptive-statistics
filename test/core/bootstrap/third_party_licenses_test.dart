import 'package:descriptive_statistics/core/bootstrap/app_bootstrap.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('registers the KaTeX fonts license used by the course formulas', () async {
    registerThirdPartyLicenses();

    final entries = await LicenseRegistry.licenses.toList();
    final katex = entries.where((e) => e.packages.contains('KaTeX fonts (flutter_math_fork)'));

    expect(katex, hasLength(1));
    expect(katex.single.paragraphs.map((p) => p.text).join(' '), contains('Khan Academy'));
  });
}
