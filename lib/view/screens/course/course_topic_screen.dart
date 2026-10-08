import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/course.dart';
import '../../../core/providers/course/course_provider.dart';
import '../../../core/providers/main/home_provider.dart';
import '../../../core/routes/app_route.dart';
import '../../../core/services/i18n/translations.g.dart';
import '../../components/course/course_blocks.dart';
import '../../themes/app_theme.dart';

/// One topic of the course: its definition, formulas and symbols, links
/// to the calculators that compute it, and to the previous/next topics.
class CourseTopicScreen extends ConsumerWidget {
  final String topicId;

  const CourseTopicScreen({required this.topicId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageCode = TranslationProvider.of(context).locale.languageCode;
    final course = ref.watch(courseProvider(languageCode)).value;
    final topic = course?.topic(topicId);

    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        title: Text(topic?.title ?? context.t.documentation, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.getAppbarBgColor(),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => context.pop(),
        ),
      ),
      body: switch ((course, topic)) {
        (final course?, final topic?) => _TopicBody(course: course, topic: topic),
        (_?, null) => Center(child: Text(context.t.anErrorOccurred)),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _TopicBody extends ConsumerWidget {
  final Course course;
  final CourseTopic topic;

  const _TopicBody({required this.course, required this.topic});

  void _openCalculator(BuildContext context, WidgetRef ref, CourseCalculator calculator) {
    ref.read(homeProvider.notifier).tabIndex = switch (calculator) {
      CourseCalculator.discrete => HomeTab.discrete,
      CourseCalculator.continuous => HomeTab.continuous,
      CourseCalculator.qualitative => HomeTab.qualitative,
    };
    context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topics = course.topics.toList();
    final index = topics.indexWhere((t) => t.id == topic.id);
    final previous = index > 0 ? topics[index - 1] : null;
    final next = index < topics.length - 1 ? topics[index + 1] : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        for (final block in topic.blocks) Padding(padding: const EdgeInsets.only(bottom: 16), child: CourseBlockView(block)),
        for (final calculator in topic.calculators)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: OutlinedButton.icon(
              onPressed: () => _openCalculator(context, ref, calculator),
              icon: Icon(switch (calculator) {
                CourseCalculator.discrete => Icons.pin,
                CourseCalculator.continuous => Icons.show_chart,
                CourseCalculator.qualitative => Icons.category,
              }),
              label: Text(switch (calculator) {
                CourseCalculator.discrete => context.t.courseOpenDiscrete,
                CourseCalculator.continuous => context.t.courseOpenContinuous,
                CourseCalculator.qualitative => context.t.courseOpenQualitative,
              }),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
            ),
          ),
        const SizedBox(height: 24),
        Divider(color: courseDividerColor(context)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: previous == null ? const SizedBox() : _SiblingLink(topic: previous, isNext: false)),
            const SizedBox(width: 12),
            Expanded(child: next == null ? const SizedBox() : _SiblingLink(topic: next, isNext: true)),
          ],
        ),
      ],
    );
  }
}

/// Replaces the current topic page with the previous or next one, so
/// that Back always returns to the topic list.
class _SiblingLink extends StatelessWidget {
  final CourseTopic topic;
  final bool isNext;

  const _SiblingLink({required this.topic, required this.isNext});

  @override
  Widget build(BuildContext context) {
    final align = isNext ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final textAlign = isNext ? TextAlign.end : TextAlign.start;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => CourseTopicRoute(topicId: topic.id).pushReplacement(context),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: align,
          children: [
            Text(
              isNext ? '${context.t.next} ›' : '‹ ${context.t.previous}',
              style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: 2),
            Text(
              topic.title,
              textAlign: textAlign,
              style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.secondary),
            ),
          ],
        ),
      ),
    );
  }
}
