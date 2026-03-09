import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:home_widget/home_widget.dart';
import 'package:unipi_orario/entities/lesson.dart';
import 'package:unipi_orario/helper/app_database.dart';
import 'package:unipi_orario/helper/recurrence_helper.dart';
import 'package:unipi_orario/services/internal_api.dart';

final InternalAPI internalAPI = Get.find<InternalAPI>();
final AppDatabase db = Get.find<AppDatabase>();

const String widgetSharedPrefsKey = "lessonWidget";
const String widgetAndroidName = "glance.HomeWidgetReceiver";
const String widgetIosName = "HomeWidget";
bool serverRunning = false;

void saveLessonsToHomeWidget() async {
  if (kIsWeb) return;

  final DateTime rangeStart = DateTime.now().subtract(const Duration(days: 1));
  final DateTime rangeEnd = rangeStart.add(const Duration(days: 60));

  final rows = await db.getUpcomingLessons(limit: 50);
  final List<LessonModel> remoteLessons = rows.map((r) => r.toModel()).where((l) => !l.isLocal).toList();

  final localTemplateRows = await db.getLocalTemplates();
  final List<LessonModel> localTemplates = localTemplateRows.map((r) => r.toModel()).toList();

  final List<LessonModel> merged = mergeLessons(
    remoteLessons: remoteLessons,
    localTemplates: localTemplates,
    rangeStart: rangeStart,
    rangeEnd: rangeEnd,
  );

  final List<LessonModel> lessons = merged.where((l) => !internalAPI.filteringCourses.contains(l.courseName ?? l.name)).toList();

  try {
    Map<String, List<LessonModel>> lessonsDict = {};
    for (final lesson in lessons) {
      final key = lesson.startDateTime.toIso8601String().split("T")[0];
      lessonsDict.putIfAbsent(key, () => []).add(lesson);
    }

    var lessonJson = jsonEncode(lessonsDict);
    if (Platform.isAndroid) HomeWidget.saveWidgetData(widgetSharedPrefsKey, lessonJson);
    if (Platform.isIOS) setUpWebServer(lessonJson);

    debugPrint("Saved widget data");
  } catch (e) {
    debugPrint("Error saving widget data: $e");
  }
}

void setUpWebServer(String jsonData) async {
  if (serverRunning) return;

  serverRunning = true;
  var server = await HttpServer.bind(InternetAddress.loopbackIPv4, 11341);
  debugPrint("Server running on ${server.address}:${server.port}");
  server.listen((HttpRequest request) {
    debugPrint("Request received");
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonData);
    request.response.close();

    server.close();
    debugPrint("Server closed");

    serverRunning = false;
  });
}

void updateHomeWidget() async {
  if (kIsWeb) return;

  var widgetList = await HomeWidget.getInstalledWidgets();
  if (widgetList.isEmpty) return;
  debugPrint(widgetList.toString());

  saveLessonsToHomeWidget();
  HomeWidget.updateWidget(
    androidName: widgetAndroidName,
    iOSName: widgetIosName,
  );
}
