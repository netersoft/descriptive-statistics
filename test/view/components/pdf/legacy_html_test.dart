import 'package:descriptive_statistics/view/components/pdf/legacy_html.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseLegacyHtml', () {
    test('splits lines on <br>, a blank line being an empty one', () {
      expect(parseLegacyHtml('a<br>b<br><br>c'), [
        [const HtmlRun('a')],
        [const HtmlRun('b')],
        <HtmlRun>[],
        [const HtmlRun('c')],
      ]);
    });

    test('applies nested bold, italic, underline and font colors', () {
      final lines = parseLegacyHtml("<b><font color='blue'><u>MEAN</u></font></b> x <font color=\"red\">y <i>z</i></font>");
      expect(lines.single, [
        const HtmlRun('MEAN', bold: true, underline: true, color: 'blue'),
        const HtmlRun(' x '),
        const HtmlRun('y ', color: 'red'),
        const HtmlRun('z', italic: true, color: 'red'),
      ]);
    });

    test('keeps the outer color inside a <font> without one', () {
      final lines = parseLegacyHtml("<font color='red'>a<font size='2'>b</font>c</font>d");
      expect(lines.single, [
        const HtmlRun('a', color: 'red'),
        const HtmlRun('b', color: 'red'),
        const HtmlRun('c', color: 'red'),
        const HtmlRun('d'),
      ]);
    });

    test('decodes the entities the explanations use', () {
      expect(parseLegacyHtml('&sum;Xi&sup2;Ni &sigma; = &radic;V &amp; &#963; &#x3C3;').single.single.text, '∑Xi²Ni σ = √V & σ σ');
    });

    test('collapses whitespace like a browser, and drops it at line ends', () {
      final lines = parseLegacyHtml('\n  Classe :\t[<b>0</b> - 10[  <br>\n  next');
      expect(lines, [
        [const HtmlRun('Classe : ['), const HtmlRun('0', bold: true), const HtmlRun(' - 10[')],
        [const HtmlRun('next')],
      ]);
    });

    test('keeps the text of unsupported tags', () {
      expect(parseLegacyHtml('<p>a <span>b</span></p>').single, [const HtmlRun('a '), const HtmlRun('b')]);
    });
  });
}
