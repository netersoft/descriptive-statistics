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

  group('groupContinuousSeries', () {
    List<(double, double, int)> group(String text, {String start = '', String width = ''}) => [
      for (final c in groupContinuousSeries(text, start: start, width: width)) (c.lower, c.upper, c.count),
    ];

    Matcher throwsRawSeries(RawSeriesError error, String token) =>
        throwsA(isA<RawSeriesException>().having((e) => e.error, 'error', error).having((e) => e.token, 'token', token));

    test('counts values per class, a value on a bound going into the class that starts there', () {
      expect(group('0 5 9,9 10 12 20', start: '0', width: '10'), [(0, 10, 3), (10, 20, 2), (20, 30, 1)]);
    });

    test('keeps empty classes so the classes stay contiguous', () {
      expect(group('1 2 25', start: '0', width: '10'), [(0, 10, 2), (10, 20, 0), (20, 30, 1)]);
    });

    test('computes clean bounds for decimal widths', () {
      expect(group('0,1 0,3 0,45', start: '0', width: '0,1'), [(0, 0.1, 0), (0.1, 0.2, 1), (0.2, 0.3, 0), (0.3, 0.4, 1), (0.4, 0.5, 1)]);
    });

    test('chooses the start and width when left blank', () {
      // 12 values over [3, 47]: Sturges gives 5 classes of 44/5 = 8.8,
      // rounded up to 10, starting at 0.
      expect(group('3 7 12 15 18 22 25 29 33 38 41 47'), [(0, 10, 2), (10, 20, 3), (20, 30, 3), (30, 40, 2), (40, 50, 2)]);
      // Only the width given: the start still follows it.
      expect(group('3 7 12', width: '5'), [(0, 5, 1), (5, 10, 1), (10, 15, 1)]);
    });

    test('handles a series of identical values', () {
      expect(group('4 4 4'), [(4, 5, 3)]);
    });

    test('rejects a bad value, start or width', () {
      expect(() => group('1 abc'), throwsRawSeries(RawSeriesError.invalidValue, 'abc'));
      expect(() => group('1 2', start: 'x'), throwsRawSeries(RawSeriesError.invalidStart, 'x'));
      expect(() => group('1 2', width: '0'), throwsRawSeries(RawSeriesError.invalidWidth, '0'));
      expect(() => group('1 2', width: '-2'), throwsRawSeries(RawSeriesError.invalidWidth, '-2'));
    });

    test('rejects a start above the smallest value, naming it as typed', () {
      expect(() => group('5 2,5 8', start: '3'), throwsRawSeries(RawSeriesError.startAboveMin, '2,5'));
    });

    test('rejects more classes than maxClasses', () {
      expect(() => group('0 1000', width: '1'), throwsRawSeries(RawSeriesError.tooManyClasses, '$maxClasses'));
    });

    test('is empty for blank input', () {
      expect(group(' \n'), isEmpty);
    });
  });

  group('suggestClasses', () {
    test('rounds the width up to 1, 2, 2.5 or 5 times a power of ten', () {
      // 8 values -> 4 classes.
      expect(suggestClasses([0, 1, 2, 3, 4, 5, 6, 7]), (start: 0.0, width: 2.0));
      expect(suggestClasses([0, 1, 2, 3, 4, 5, 6, 9]), (start: 0.0, width: 2.5));
      expect(suggestClasses([0.12, 0.2, 0.3, 0.33, 0.4, 0.5, 0.6, 0.7]), (start: 0.0, width: 0.2));
    });

    test('starts at a multiple of the width, below negative values too', () {
      expect(suggestClasses([-7, -3, 0, 4]).start, -10);
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
