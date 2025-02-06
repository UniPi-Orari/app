import 'dart:convert';
import 'dart:io';

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
const String widgetAndroidName = "glance.HomeWidgetReceiver";
const String widgetIosName = "HomeWidget";
bool serverRunning = false;

void saveLessonsToHomeWidget() {
  List<Lesson> lessons = objectBox.lessonBox
      .query(
        Lesson_.startDateTime.greaterThanDate(DateTime.now().subtract(const Duration(days: 1))),
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
  var widgetList = await HomeWidget.getInstalledWidgets();
  if (widgetList.isEmpty) return;
  debugPrint(widgetList.toString());

  saveLessonsToHomeWidget();
  HomeWidget.updateWidget(
    androidName: widgetAndroidName,
    iOSName: widgetIosName,
  );
}
