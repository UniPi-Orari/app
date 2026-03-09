import 'package:unipi_orario/objectbox.g.dart';
import 'package:uuid/uuid.dart';
import 'package:unipi_orario/entities/lesson.dart';
import 'package:unipi_orario/helper/object_box.dart';
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
  final ObjectBox objectBox = Get.find<ObjectBox>();
  final bool isRecurring = recurrenceRule != null && recurrenceRule != 'NONE';

  final lesson = Lesson(
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

  await objectBox.lessonBox.putAsync(lesson);

  if (isRecurring) {
    cachedLessons.clear();
  } else {
    invalidateLocalCache([startDateTime]);
  }
}

Future<void> deleteLocalLesson(int id) async {
  final ObjectBox objectBox = Get.find<ObjectBox>();
  final lesson = objectBox.lessonBox.get(id);
  objectBox.lessonBox.remove(id);
  if (lesson != null) {
    invalidateLocalCache([lesson.startDateTime]);
  }
}

Future<void> deleteLocalLessonSeries(String groupId) async {
  final ObjectBox objectBox = Get.find<ObjectBox>();
  final box = objectBox.lessonBox;
  await box.query(Lesson_.recurrenceGroupId.equals(groupId)).build().removeAsync();
  cachedLessons.clear();
}
