import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unipi_orario/entities/lesson.dart';
import 'package:unipi_orario/helper/object_box.dart';
import 'package:unipi_orario/helper/recurrence_helper.dart';
import 'package:unipi_orario/objectbox.g.dart';
import 'package:unipi_orario/services/internal_api.dart';
import 'package:unipi_orario/services/widget_handler.dart';
import 'package:unipi_orario_wrapper/unipi_orario_wrapper.dart' as w;

final wrapper = w.WrapperService();

InternalAPI internalAPI = Get.find<InternalAPI>();
ObjectBox objectBox = Get.find<ObjectBox>();

Map<String, List<Lesson>> cachedLessons = {};
late DateTime currentCachedWeek;

// Use a Completer to prevent duplicate API calls
Completer<void>? _currentCacheOperation;
DateTime? _lastCacheRefresh;

Future<List<Lesson>> getLessonsFromCache({
  required DateTime startTime,
  required DateTime endTime,
  bool forceRefresh = false,
  int maxRetries = 3,
}) async {
  final DateTime exactStartDate = DateTime(startTime.year, startTime.month, startTime.day);
  final DateTime exactEndDate = DateTime(endTime.year, endTime.month, endTime.day);
  final box = objectBox.lessonBox;

  final cache = await box
      .query(
        Lesson_.startDateTime.betweenDate(exactStartDate, exactEndDate),
      )
      .order(Lesson_.startDateTime)
      .build()
      .findAsync();

  if (cache.isEmpty || forceRefresh) {
    if (maxRetries > 0) {
      await cacheLessons();
      return await getLessonsFromCache(
        startTime: startTime,
        endTime: endTime,
        maxRetries: maxRetries - 1,
      );
    }
  }

  return cache;
}

Future<List<Lesson>> getLessonsForWeek(
  DateTime date, {
  int depth = 1,
}) async {
  assert(depth > 0);

  final DateTime weekStart = getFirstWeekDay(date);
  final String weekStartStr = weekStart.toIso8601String();

  // Return cached lessons if available
  if (cachedLessons.containsKey(weekStartStr)) {
    return cachedLessons[weekStartStr]!;
  }

  // If no cache exists, we need to fetch more weeks
  if (cachedLessons.isEmpty) {
    depth = max(depth, 2);
  }

  // Fetch the requested week first
  await cacheWeekLessons(startDay: weekStart);

  // Then fetch surrounding weeks if needed
  for (int i = 1; i < depth; i++) {
    for (int j = 0; j < 2; j++) {
      final int multiplier = j == 0 ? -1 : 1;
      final DateTime newWeek = weekStart.add(Duration(days: 7 * multiplier));
      await cacheWeekLessons(startDay: newWeek);
    }
  }

  // Check if lessons were actually cached (might be skipped due to recent refresh)
  if (!cachedLessons.containsKey(weekStartStr)) {
    // If not, fetch directly from database
    final endDay = weekStart.add(const Duration(days: 6));
    final List<Lesson> lessons = await getLessonsFromCache(
      startTime: weekStart,
      endTime: endDay,
      forceRefresh: false, // Don't force refresh to avoid loops
    );

    cachedLessons[weekStartStr] = lessons;
  }

  return cachedLessons[weekStartStr]!;
}

Future<void> cacheWeekLessons({required DateTime startDay, DateTime? endDay}) async {
  final String dateString = startDay.toIso8601String();

  // If already cached, return immediately
  if (cachedLessons.containsKey(dateString)) {
    return;
  }

  endDay ??= startDay.add(const Duration(days: 6));

  // Check if we have data in database before attempting to cache
  final box = objectBox.lessonBox;
  final existingCount = await box
      .query(
        Lesson_.startDateTime.betweenDate(startDay, endDay),
      )
      .build()
      .count();

  // If we don't have data and we're skipping cache refresh, fetch directly
  if (existingCount == 0) {
    // Force a cache refresh but only if not too recent
    await cacheLessons();
  }

  final List<Lesson> lessons = await getLessonsFromCache(
    startTime: startDay,
    endTime: endDay,
  );

  cachedLessons[dateString] = lessons;
}

DateTime getFirstWeekDay(DateTime date) {
  final DateTime exactDate = DateTime(date.year, date.month, date.day);
  return exactDate.subtract(Duration(days: exactDate.weekday - 1));
}

Future<List<Lesson>> getLessonsForDay(DateTime day) async {
  final DateTime exactDate = DateTime(day.year, day.month, day.day);
  final DateTime dayEnd = exactDate.add(const Duration(hours: 23, minutes: 59));

  // Get lessons for the week
  await getLessonsForWeek(day);

  final String weekStartStr = getFirstWeekDay(exactDate).toIso8601String();

  // Make sure we have the cached lessons
  if (!cachedLessons.containsKey(weekStartStr)) {
    // If not, fetch directly from database
    final startWeek = getFirstWeekDay(exactDate);
    final endWeek = startWeek.add(const Duration(days: 6));
    final lessons = await getLessonsFromCache(
      startTime: startWeek,
      endTime: endWeek,
    );
    cachedLessons[weekStartStr] = lessons;
  }

  final box = objectBox.lessonBox;
  final localTemplates = await box.query(Lesson_.isLocal.equals(true)).build().findAsync();
  final remoteLessons = cachedLessons[weekStartStr]!.where((l) => l.startDateTime.day == day.day && !l.isLocal).toList();

  return mergeLessons(
    remoteLessons: remoteLessons,
    localTemplates: localTemplates,
    rangeStart: exactDate,
    rangeEnd: dayEnd,
  );
}

Future<void> cacheLessons() async {
  // Check if we recently refreshed (within last 30 seconds)
  if (_lastCacheRefresh != null && DateTime.now().difference(_lastCacheRefresh!) < const Duration(seconds: 30)) {
    debugPrint("Cache was recently refreshed, skipping...");
    return;
  }

  // If we're already caching, wait for the existing operation to complete
  if (_currentCacheOperation != null) {
    debugPrint("Waiting for existing cache operation...");
    await _currentCacheOperation!.future;
    return;
  }

  debugPrint("Starting cacheLessons operation...");
  _currentCacheOperation = Completer<void>();

  try {
    final List<Lesson> lessons = await getLessons();

    final box = objectBox.lessonBox;
    await box.query(Lesson_.isLocal.equals(false)).build().removeAsync(); // keep local lessons
    await box.putManyAsync(lessons);

    // Clear memory cache since we have new data
    cachedLessons.clear();

    updateHomeWidget();

    _lastCacheRefresh = DateTime.now();
    debugPrint("cacheLessons completed successfully");
  } catch (e) {
    debugPrint("Error in cacheLessons: $e");
    rethrow;
  } finally {
    _currentCacheOperation?.complete();
    _currentCacheOperation = null;
  }
}

Future<List<String>> getAllCourses({int retries = 5}) async {
  if (retries <= 0) return [];

  final box = objectBox.lessonBox;
  final lessons = await box.getAllAsync();

  if (lessons.isEmpty) {
    // Only cache if not already cached recently
    await cacheLessons();
    return await getAllCourses(retries: retries - 1);
  }

  final Set<String> courses = {};
  for (final lesson in lessons) {
    if (lesson.courseName != null && lesson.courseName!.isNotEmpty) {
      courses.add(lesson.courseName!);
    } else if (lesson.name.isNotEmpty) {
      courses.add(lesson.name);
    }
  }

  return courses.toList()..sort();
}

void invalidateLocalCache(List<DateTime> dates) {
  for (final date in dates) {
    final key = getFirstWeekDay(date).toIso8601String();
    cachedLessons.remove(key);
  }
}

Future<void> refreshCaches() async {
  debugPrint("refreshCaches called");

  // Force a refresh regardless of timestamp
  _lastCacheRefresh = null;

  // Clear all caches
  cachedLessons.clear();

  // Perform a fresh cache
  await cacheLessons();
}

Future<List<Lesson>> getLessons() async {
  debugPrint("getLessons: Fetching from API...");
  final now = DateTime.now();
  final startYear = now.month >= 9 ? now.year : now.year - 1;
  final endYear = now.month >= 7 ? now.year + 1 : now.year;

  final lessons = await wrapper.fetchLessons(
    calendarId: internalAPI.calendarId,
    startDate: DateTime(startYear, 9, 15),
    endDate: DateTime(endYear, 7, 1),
  );

  debugPrint("getLessons: Got ${lessons.length} lessons from API");
  return [for (final lesson in lessons) Lesson.fromJsonData(lesson)];
}
