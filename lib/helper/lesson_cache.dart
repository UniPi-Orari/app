import 'package:uuid/uuid.dart';
import 'package:unipi_orario/entities/lesson.dart';
import 'package:unipi_orario/helper/app_database.dart';
import 'package:unipi_orario/services/wrapper_impl.dart';
import 'package:get/get.dart';

const _uuid = Uuid();

Future<void> saveLocalLesson({
  required String name,
  required DateTime startDateTime,
  required DateTime endDateTime,
  String roomName = '',
  String? courseName,
  String? recurrenceRule,
  DateTime? recurrenceEndDate,
}) async {
  final AppDatabase db = Get.find<AppDatabase>();
  final bool isRecurring = recurrenceRule != null && recurrenceRule != 'NONE';

  final lesson = LessonModel(
    name: name,
    startDateTime: startDateTime,
    endDateTime: endDateTime,
    roomName: roomName,
    courseName: courseName,
    isLocal: true,
    recurrenceRule: isRecurring ? recurrenceRule : 'NONE',
    recurrenceEndDate: isRecurring ? recurrenceEndDate : null,
    recurrenceGroupId: isRecurring ? _uuid.v4() : null,
  );

  await db.insertLesson(lesson.toCompanion());

  if (isRecurring) {
    cachedLessons.clear();
  } else {
    invalidateLocalCache([startDateTime]);
  }
}

Future<void> deleteLocalLesson(int id) async {
  final AppDatabase db = Get.find<AppDatabase>();
  final all = await db.getAllLessons();
  final lesson = all.where((l) => l.id == id).firstOrNull;

  await db.deleteLessonById(id);

  if (lesson != null) {
    invalidateLocalCache([lesson.startDateTime]);
  }
}

Future<void> deleteLocalLessonSeries(String groupId) async {
  final AppDatabase db = Get.find<AppDatabase>();
  await db.deleteLessonSeries(groupId);
  cachedLessons.clear();
}
