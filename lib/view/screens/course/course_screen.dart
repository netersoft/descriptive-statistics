import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/course.dart';
import '../../../core/providers/course/course_provider.dart';
import '../../../core/routes/app_route.dart';
import '../../../core/services/i18n/translations.g.dart';
import '../../components/course/course_blocks.dart';

/// The Course tab: the course's topics grouped by section, with a search
/// field. Each topic opens on its own page ([CourseTopicScreen]).
class CourseScreen extends ConsumerStatefulWidget {
  const CourseScreen({super.key});

  @override
  ConsumerState<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends ConsumerState<CourseScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Read through TranslationProvider so the tab reloads the course when
    // the language changes, even while it stays alive in the TabBarView.
    final languageCode = TranslationProvider.of(context).locale.languageCode;
    return switch (ref.watch(courseProvider(languageCode))) {
      AsyncData(:final value) => _buildList(context, value),
      AsyncError() => Center(child: Text(context.t.anErrorOccurred)),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }

  Widget _buildList(BuildContext context, Course course) {
    final query = foldForSearch(_query.trim());
    final sections = [
      for (final section in course.sections)
        (
          section,
          [
            for (final topic in section.topics)
              if (query.isEmpty || foldForSearch(topic.searchableText).contains(query)) topic,
          ],
        ),
    ].where((s) => s.$2.isNotEmpty).toList();
    final accent = Theme.of(context).colorScheme.secondary;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _query = value),
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          decoration: InputDecoration(
            hintText: context.t.courseSearchHint,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                    onPressed: () => setState(() {
                      _searchController.clear();
                      _query = '';
                    }),
                  ),
            filled: true,
            fillColor: coursePanelColor(context),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        if (sections.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 32),
            child: Text(context.t.courseNoResult(query: _query.trim()), textAlign: TextAlign.center),
          ),
        for (final (section, topics) in sections) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
            child: Text(
              section.title.toUpperCase(),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: accent),
            ),
          ),
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final (i, topic) in topics.indexed) ...[
                  if (i > 0) Divider(height: 1, indent: 16, endIndent: 16, color: courseDividerColor(context)),
                  ListTile(
                    title: Text(topic.title),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      CourseTopicRoute(topicId: topic.id).push<void>(context);
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

const _accentFolds = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'ç': 'c', 'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', //
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', 'ñ': 'n', 'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', //
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ß': 'ss', 'œ': 'oe', 'æ': 'ae',
};

/// Lower-cases [text] and strips its accents, so that searching "ecart"
/// finds "Écart type" and "mediana" finds "Mediana".
String foldForSearch(String text) => text.toLowerCase().split('').map((c) => _accentFolds[c] ?? c).join();
