import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unipi_orario/entities/lesson.dart';
import 'package:unipi_orario/helper/object_box.dart';
import 'package:unipi_orario/objectbox.g.dart';
import 'package:unipi_orario/services/internal_api.dart';
import 'package:unipi_orario/services/widget_handler.dart';
import 'package:unipi_orario_wrapper/unipi_orario_wrapper.dart' as w;

final wrapper = w.WrapperService();

InternalAPI internalAPI = Get.find<InternalAPI>();
ObjectBox objectBox = Get.find<ObjectBox>();

Map<String, List<Lesson>> cachedLessons = {};
late DateTime currentCachedWeek;

bool cachedBeingCalled = false;

Future<List<Lesson>> getLessonsFromCache({
  required DateTime startTime,
  required DateTime endTime,
  bool forceRefresh = false,
  int maxRetries = 3,
}) async {
  DateTime exactStartDate = DateTime(startTime.year, startTime.month, startTime.day);
  DateTime exactEndDate = DateTime(endTime.year, endTime.month, endTime.day);
  var box = objectBox.lessonBox;

  var cache = await box
      .query(
        Lesson_.startDateTime.betweenDate(exactStartDate, exactEndDate),
      )
      .order(Lesson_.startDateTime)
      .build()
      .findAsync();

  if ((cache.isEmpty || forceRefresh) && maxRetries > 0) {
    await cacheLessons();
    return await getLessonsFromCache(
      startTime: startTime,
      endTime: endTime,
      maxRetries: maxRetries - 1,
    );
  }

  return cache;
}

Future<List<Lesson>> getLessonsForWeek(
  DateTime date, {
  int depth = 1,
}) async {
  assert(depth > 0);

  DateTime weekStart = getFirstWeekDay(date);
  String weekStartStr = weekStart.toIso8601String();

  if (cachedLessons.containsKey(weekStartStr)) {
    return cachedLessons[weekStartStr]!;
  }

  if (cachedLessons.isEmpty) {
    depth = max(depth, 2);
  }

  for (int i = 0; i < depth; i++) {
    if (i == 0) {
      await cacheWeekLessons(startDay: weekStart);
      continue;
    }

    for (int j = 0; j < 2; j++) {
      int multiplier = j == 0 ? -1 : 1;
      DateTime newWeek = weekStart.add(Duration(days: 7 * multiplier));
      await cacheWeekLessons(startDay: newWeek);
    }
  }

  return cachedLessons[weekStartStr]!;
}

Future<void> cacheWeekLessons({required DateTime startDay, DateTime? endDay}) async {
  String dateString = startDay.toIso8601String();
  if (cachedLessons.containsKey(dateString)) {
    return;
  }

  endDay = endDay ?? startDay.add(const Duration(days: 6));
  List<Lesson> lessons = await getLessonsFromCache(
    startTime: startDay,
    endTime: endDay,
  );

  cachedLessons[dateString] = lessons;
}

DateTime getFirstWeekDay(DateTime date) {
  // gio - mer = lun
  DateTime exactDate = DateTime(date.year, date.month, date.day);
  return exactDate.subtract(Duration(days: exactDate.weekday - 1));
}

Future<List<Lesson>> getLessonsForDay(DateTime day) async {
  // get the lesson from the cache
  DateTime exactDate = DateTime(day.year, day.month, day.day);
  String weekStartStr = getFirstWeekDay(exactDate).toIso8601String();

  await getLessonsForWeek(day);

  List<Lesson> lessons = cachedLessons[weekStartStr]!;
  return lessons.where((lesson) => lesson.startDateTime.day == day.day).toList();
}

Future<void> cacheLessons() async {
  if (cachedBeingCalled) {
    return;
  }
  cachedBeingCalled = true;

  List<Lesson> lessons = await getLessons();

  var box = objectBox.lessonBox;
  await box.removeAllAsync();
  await box.putManyAsync(lessons);
  updateHomeWidget();

  cachedBeingCalled = false;
}

Future<List<String>> getAllCourses() async {
  var box = objectBox.lessonBox;
  var lessons = await box.getAllAsync();

  if (lessons.isEmpty) {
    await cacheLessons();
    return await getAllCourses();
  }

  Set<String> courses = {};
  for (var lesson in lessons) {
    courses.add(lesson.courseName ?? lesson.name);
  }

  return courses.toList();
}

Future<void> refreshCaches() async {
  await objectBox.lessonBox.removeAllAsync();
  cachedLessons.clear();
  await cacheLessons();
}

Future<List<Lesson>> getLessons() async {
  debugPrint("getting lessons from api");
  var lessons = await wrapper.fetchLessons(
    calendarId: internalAPI.calendarId,
    startDate: DateTime(2024, 9, 16),
    endDate: DateTime(2025, 7, 1),
  );

  debugPrint("got lessons from api ${lessons.length}");
  return [for (var lesson in lessons) Lesson.fromJsonData(lesson)];
}
