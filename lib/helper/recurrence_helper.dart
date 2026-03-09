import 'package:unipi_orario/entities/lesson.dart';

List<LessonModel> expandRecurringLesson({
  required LessonModel template,
  required DateTime rangeStart,
  required DateTime rangeEnd,
}) {
  if (!template.isRecurring) return [template];

  final rule = template.recurrenceRule!;
  final effectiveEnd = template.recurrenceEndDate ?? rangeEnd;

  final clampedEnd = effectiveEnd.isBefore(rangeEnd) ? effectiveEnd : rangeEnd;

  final List<int> activeDays = _parseActiveDays(rule);
  final List<LessonModel> instances = [];

  DateTime cursor = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
  final clampedEndDate = DateTime(clampedEnd.year, clampedEnd.month, clampedEnd.day);
  final templateStartDate = DateTime(
    template.startDateTime.year,
    template.startDateTime.month,
    template.startDateTime.day,
  );

  while (!cursor.isAfter(clampedEndDate)) {
    final bool matchesRule = _dateMatchesRule(cursor, rule, activeDays);
    final bool isOnOrAfterTemplateStart = !cursor.isBefore(templateStartDate);

    if (matchesRule && isOnOrAfterTemplateStart) {
      instances.add(template.copyWithDate(cursor));
    }

    cursor = cursor.add(const Duration(days: 1));
  }

  return instances;
}

List<LessonModel> mergeLessons({
  required List<LessonModel> remoteLessons,
  required List<LessonModel> localTemplates,
  required DateTime rangeStart,
  required DateTime rangeEnd,
}) {
  final List<LessonModel> allLessons = [...remoteLessons];

  for (final template in localTemplates) {
    if (template.isRecurring) {
      allLessons.addAll(expandRecurringLesson(
        template: template,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      ));
    } else {
      // only include single events for that specific day
      final lessonDate = DateTime(
        template.startDateTime.year,
        template.startDateTime.month,
        template.startDateTime.day,
      );
      final rangeStartDate = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
      final rangeEndDate = DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day);

      if (!lessonDate.isBefore(rangeStartDate) && !lessonDate.isAfter(rangeEndDate)) {
        allLessons.add(template);
      }
    }
  }

  allLessons.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
  return allLessons;
}

/// Parses weekday numbers from a rule like "WEEKLY:1,3,5"
List<int> _parseActiveDays(String rule) {
  if (!rule.startsWith('WEEKLY:')) return [];
  final parts = rule.split(':');
  if (parts.length < 2) return [];
  return parts[1].split(',').map(int.parse).toList();
}

bool _dateMatchesRule(DateTime date, String rule, List<int> activeDays) {
  if (rule == 'DAILY') return true;
  if (rule.startsWith('WEEKLY:')) {
    // DateTime.weekday: 1=Mon, 7=Sun — matches our convention
    return activeDays.contains(date.weekday);
  }
  return false;
}
