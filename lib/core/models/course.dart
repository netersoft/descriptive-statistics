/// The descriptive-statistics course, read from `assets/docs/<locale>/course.json`.
///
/// Every locale's file has the same sections, topics and blocks in the same
/// order (checked by test/assets/course_test.dart): only the text differs.
class Course {
  final List<CourseSection> sections;

  const Course({required this.sections});

  factory Course.fromJson(Map<String, dynamic> json) => Course(
    sections: [for (final s in json['sections'] as List) CourseSection.fromJson(s as Map<String, dynamic>)],
  );

  Iterable<CourseTopic> get topics => sections.expand((s) => s.topics);

  CourseTopic? topic(String id) => topics.where((t) => t.id == id).firstOrNull;
}

class CourseSection {
  final String id;
  final String title;
  final List<CourseTopic> topics;

  const CourseSection({required this.id, required this.title, required this.topics});

  factory CourseSection.fromJson(Map<String, dynamic> json) => CourseSection(
    id: json['id'] as String,
    title: json['title'] as String,
    topics: [for (final t in json['topics'] as List) CourseTopic.fromJson(t as Map<String, dynamic>)],
  );
}

/// The calculator tab a topic can send the user to.
enum CourseCalculator { discrete, continuous, qualitative }

/// One notion of the course: its definition, its formulas and their
/// symbols on a single page.
class CourseTopic {
  final String id;
  final String title;
  final List<CourseBlock> blocks;
  final List<CourseCalculator> calculators;

  const CourseTopic({required this.id, required this.title, required this.blocks, this.calculators = const []});

  factory CourseTopic.fromJson(Map<String, dynamic> json) => CourseTopic(
    id: json['id'] as String,
    title: json['title'] as String,
    blocks: [for (final b in json['blocks'] as List) CourseBlock.fromJson(b as Map<String, dynamic>)],
    calculators: [for (final c in (json['calculators'] as List?) ?? const []) CourseCalculator.values.byName(c as String)],
  );

  /// Plain text of the title and every block, for the search field.
  String get searchableText => [title, ...blocks.map((b) => b.searchableText)].join(' ');
}

sealed class CourseBlock {
  const CourseBlock();

  factory CourseBlock.fromJson(Map<String, dynamic> json) => switch (json['type']) {
    'text' => CourseText(json['text'] as String),
    'bullets' => CourseBullets([for (final i in json['items'] as List) i as String]),
    'formula' => CourseFormula(
      label: json['label'] as String?,
      text: json['text'] as String?,
      tex: json['tex'] as String?,
      legend: [
        for (final l in (json['legend'] as List?) ?? const []) CourseSymbol(tex: (l as Map<String, dynamic>)['tex'] as String, text: l['text'] as String),
      ],
    ),
    'table' => CourseTable(
      caption: json['caption'] as String,
      headers: [for (final h in json['headers'] as List) h as String],
      rows: [
        for (final r in json['rows'] as List) [for (final c in r as List) c as String],
      ],
    ),
    'tree' => CourseTree(CourseTreeNode.fromJson(json['root'] as Map<String, dynamic>)),
    final type => throw FormatException('Unknown course block type: $type'),
  };

  String get searchableText;
}

/// A paragraph; `**…**` marks bold terms.
class CourseText extends CourseBlock {
  final String text;

  const CourseText(this.text);

  @override
  String get searchableText => text.replaceAll('**', '');
}

class CourseBullets extends CourseBlock {
  final List<String> items;

  const CourseBullets(this.items);

  @override
  String get searchableText => items.join(' ').replaceAll('**', '');
}

/// A formula card: an optional [label] (e.g. "Continuous variable"), a
/// rule in words ([text]), a LaTeX formula ([tex]), or both, and the
/// meaning of its symbols.
class CourseFormula extends CourseBlock {
  final String? label;
  final String? text;
  final String? tex;
  final List<CourseSymbol> legend;

  const CourseFormula({this.label, this.text, this.tex, this.legend = const []});

  @override
  String get searchableText => [label, text, ...legend.map((l) => l.text)].whereType<String>().join(' ');
}

class CourseSymbol {
  final String tex;
  final String text;

  const CourseSymbol({required this.tex, required this.text});
}

/// A small example table (e.g. a statistical table).
class CourseTable extends CourseBlock {
  final String caption;
  final List<String> headers;
  final List<List<String>> rows;

  const CourseTable({required this.caption, required this.headers, required this.rows});

  @override
  String get searchableText => caption;
}

/// A classification drawn as a tree (e.g. the types of variables).
class CourseTree extends CourseBlock {
  final CourseTreeNode root;

  const CourseTree(this.root);

  @override
  String get searchableText => root.labels.join(' ');
}

class CourseTreeNode {
  final String label;
  final String? example;
  final List<CourseTreeNode> children;

  const CourseTreeNode({required this.label, this.example, this.children = const []});

  factory CourseTreeNode.fromJson(Map<String, dynamic> json) => CourseTreeNode(
    label: json['label'] as String,
    example: json['example'] as String?,
    children: [for (final c in (json['children'] as List?) ?? const []) CourseTreeNode.fromJson(c as Map<String, dynamic>)],
  );

  Iterable<String> get labels sync* {
    yield label;
    if (example != null) yield example!;
    for (final c in children) {
      yield* c.labels;
    }
  }
}
