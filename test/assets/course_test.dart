import 'dart:convert';
import 'dart:io';

import 'package:descriptive_statistics/core/models/course.dart';
import 'package:flutter_math_fork/tex.dart';
import 'package:flutter_test/flutter_test.dart';

/// Everything about a block except its translated text: two locales'
/// courses must have the same shapes in the same order.
Object? _shape(CourseBlock block) => switch (block) {
  CourseText() => 'text',
  CourseBullets(:final items) => ['bullets', items.length],
  CourseFormula(:final label, :final text, :final tex, :final legend) => [
    'formula',
    label != null,
    text != null,
    tex,
    [for (final l in legend) l.tex],
  ],
  CourseTable(:final headers, :final rows) => ['table', headers.length, rows.length, rows.first.first],
  CourseTree(:final root) => ['tree', _treeShape(root)],
};

Object _treeShape(CourseTreeNode node) => [
  node.example != null,
  [for (final c in node.children) _treeShape(c)],
];

Object _courseShape(Course course) => [
  for (final section in course.sections)
    [
      section.id,
      for (final topic in section.topics)
        [
          topic.id,
          topic.calculators,
          [for (final b in topic.blocks) _shape(b)],
        ],
    ],
];

void main() {
  final locales = Directory('assets/i18n').listSync().map((f) => f.uri.pathSegments.last.split('.').first).toList()..sort();
  Course load(String locale) => Course.fromJson(jsonDecode(File('assets/docs/$locale/course.json').readAsStringSync()) as Map<String, dynamic>);

  test('every app language has a course', () {
    expect(locales, hasLength(5));
    for (final locale in locales) {
      expect(load(locale).topics, isNotEmpty, reason: locale);
    }
  });

  test('every language has the same sections, topics, formulas and symbols as French', () {
    final french = _courseShape(load('fr'));
    for (final locale in locales) {
      expect(_courseShape(load(locale)), french, reason: locale);
    }
  });

  test('topic ids are unique', () {
    final ids = load('fr').topics.map((t) => t.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('every formula and symbol is valid TeX', () {
    for (final locale in locales) {
      for (final topic in load(locale).topics) {
        for (final block in topic.blocks.whereType<CourseFormula>()) {
          for (final tex in [?block.tex, ...block.legend.map((l) => l.tex)]) {
            expect(() => TexParser(tex, const TexParserSettings()).parse(), returnsNormally, reason: '$locale/${topic.id}: $tex');
          }
        }
      }
    }
  });

  test('bold markers come in pairs', () {
    for (final locale in locales) {
      for (final topic in load(locale).topics) {
        for (final text in [
          for (final b in topic.blocks)
            ...switch (b) {
              CourseText(:final text) => [text],
              CourseBullets(:final items) => items,
              CourseFormula(:final text?) => [text],
              _ => <String>[],
            },
        ]) {
          expect('**'.allMatches(text).length.isEven, isTrue, reason: '$locale/${topic.id}: $text');
        }
      }
    }
  });
}
