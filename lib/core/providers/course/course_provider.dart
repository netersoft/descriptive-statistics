import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../models/course.dart';

part 'course_provider.g.dart';

/// The course in [languageCode]. Keyed by language so that a screen
/// watching it with the current locale reloads when the language changes.
@riverpod
Future<Course> course(Ref ref, String languageCode) async {
  // The provider already keeps the course while a screen watches it, so the
  // bundle doesn't need its own copy of the 20 KB string. (Its cached
  // Future would also be tied to the first test's fake-async zone, and
  // never complete in the next widget tests.)
  final json = await rootBundle.loadString('assets/docs/$languageCode/course.json', cache: false);
  return Course.fromJson(jsonDecode(json) as Map<String, dynamic>);
}
