import 'package:flutter_starter/core/stats/raw_series.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tallyNumericSeries', () {
    List<(double, int)> tally(String text) => [for (final t in tallyNumericSeries(text)) (t.value, t.count)];

    test('counts each value, ascending', () {
      expect(tally('3 5 5 7 3 5'), [(3, 2), (5, 3), (7, 1)]);
    });

    test('accepts spaces, semicolons, line breaks and ", " as separators', () {
      expect(tally('3, 5;5\n7   3\t5'), [(3, 2), (5, 3), (7, 1)]);
    });

    test('reads a comma between digits as a decimal separator', () {
      expect(tally('2,5 3 2.5; 4,5'), [(2.5, 2), (3, 1), (4.5, 1)]);
    });

    test('handles negative values and surrounding blanks', () {
      expect(tally('  -1 0 -1  '), [(-1, 2), (0, 1)]);
    });

    test('rejects ambiguous "3,5,5" and non-numbers, naming the bad token', () {
      expect(() => tallyNumericSeries('1 3,5,5 2'), throwsA(isA<RawSeriesException>().having((e) => e.token, 'token', '3,5,5')));
      expect(() => tallyNumericSeries('1 abc'), throwsA(isA<RawSeriesException>().having((e) => e.token, 'token', 'abc')));
    });

    test('is empty for blank input', () {
      expect(tallyNumericSeries('  \n '), isEmpty);
    });
  });

  group('tallyQualitativeSeries', () {
    List<(String, int)> tally(String text) => [for (final t in tallyQualitativeSeries(text)) (t.value, t.count)];

    test('counts each modality in first-seen order', () {
      expect(tally('Rouge; Bleu; Rouge; Vert; Bleu; Rouge'), [('Rouge', 3), ('Bleu', 2), ('Vert', 1)]);
    });

    test('keeps spaces inside modality names and splits on lines, commas and semicolons', () {
      expect(tally('Très bien\nBien, Très bien ;Passable'), [('Très bien', 2), ('Bien', 1), ('Passable', 1)]);
    });

    test('is case-sensitive and ignores empty entries', () {
      expect(tally('a;;A,a,'), [('a', 2), ('A', 1)]);
    });
  });
}
