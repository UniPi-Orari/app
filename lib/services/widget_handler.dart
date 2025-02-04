import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:home_widget/home_widget.dart';
import 'package:unipi_orario/entities/lesson.dart';
import 'package:unipi_orario/helper/object_box.dart';
import 'package:unipi_orario/objectbox.g.dart';
import 'package:unipi_orario/services/internal_api.dart';

final InternalAPI internalAPI = Get.find<InternalAPI>();
final ObjectBox objectBox = Get.find<ObjectBox>();

const String widgetSharedPrefsKey = "lessonWidget";

void saveLessonsToHomeWidget() {
  List<Lesson> lessons = objectBox.lessonBox
      .query(
        Lesson_.startDateTime.greaterThanDate(DateTime.now()),
      )
      .order(
        Lesson_.startDateTime,
      )
      .build()
      .find();
  lessons = lessons.where((element) => !internalAPI.filteringCourses.contains(element.courseName ?? element.name)).take(50).toList();

  try {
    Map<String, List<Lesson>> lessonsDict = {};
    for (Lesson? lesson in lessons) {
      String key = lesson!.startDateTime.toIso8601String().split("T")[0];

      if (!lessonsDict.containsKey(key)) lessonsDict[key] = [];
      lessonsDict[key]!.add(lesson);
    }

    debugPrint(lessonsDict.toString());
    HomeWidget.saveWidgetData(widgetSharedPrefsKey, jsonEncode(lessonsDict));
    debugPrint("Saved widget data");
  } catch (e) {
    debugPrint("Error saving widget data: $e");
  }
}

void updateHomeWidget() {
  saveLessonsToHomeWidget();
}
