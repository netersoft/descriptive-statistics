import 'package:descriptive_statistics/core/services/i18n/translations.g.dart';
import 'package:descriptive_statistics/core/stats/qualitative_stats.dart';
import 'package:descriptive_statistics/view/components/calculators/qualitative_explanation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildQualitativeExplanationHtml', () {
    final result = computeQualitativeStats(['a', 'b', 'a'], [2, 1, 4]);

    test("writes the total with the table's effectif symbol", () async {
      // French calls the column "E" (Effectifs)...
      expect(buildQualitativeExplanationHtml(result, const {}), contains('<b>E = &sum;Ni</b>'));

      // ...English "F" (Frequency); restore French afterwards for the
      // other tests.
      await AppLocale.en.build();
      await LocaleSettings.setLocaleRaw('en');
      final html = buildQualitativeExplanationHtml(result, const {});
      await LocaleSettings.setLocaleRaw('fr');

      expect(html, contains('<b>F = &sum;Ni</b>'));
      expect(html, contains('F = 7'));
      expect(html, isNot(contains('E = ')));
    });
  });
}
