import 'package:objectbox/objectbox.dart';
import 'package:unipi_orario_wrapper/unipi_orario_wrapper.dart';

@Entity()
class Lesson {
  @Id()
  int id = 0;

  final String name;
  final String? courseName;
  final String roomName;
  final bool isLocal;

  @Property(type: PropertyType.date)
  final DateTime startDateTime;

  @Property(type: PropertyType.date)
  final DateTime endDateTime;

  /// "NONE" for one-off local events
  /// "DAILY" for daily recurrence
  /// "WEEKLY:1,3,5" for specific weekdays (1=Mon, 7=Sun)
  final String? recurrenceRule;

  @Property(type: PropertyType.date)
  final DateTime? recurrenceEndDate;

  /// Shared UUID across all instances of a recurring series
  final String? recurrenceGroupId;

  Lesson({
    required this.name,
    required this.startDateTime,
    required this.endDateTime,
    this.courseName,
    required this.roomName,
    this.isLocal = false,
    this.recurrenceRule,
    this.recurrenceEndDate,
    this.recurrenceGroupId,
  });

  bool get isRecurring => recurrenceRule != null && recurrenceRule != 'NONE';

  factory Lesson.fromJsonData(Map<String, dynamic> json) {
    final parsedDates = Utils.parseLessonDates(json);

    return Lesson(
      name: json['nome'],
      startDateTime: parsedDates[0],
      endDateTime: parsedDates[1],
      courseName: json['fattoreDiPartizione'].length > 0 ? json['fattoreDiPartizione'][0]['partizioni'][0]['descrizione'] : null,
      roomName: json['aule'][0]['descrizione'],
    );
  }

  // ----- for jsonEncode and jsonDecode
  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      name: json['name'],
      startDateTime: DateTime.parse(json['startDateTime']),
      endDateTime: DateTime.parse(json['endDateTime']),
      courseName: json['courseName'],
      roomName: json['roomName'],
      isLocal: json['isLocal'] ?? false,
      recurrenceRule: json['recurrenceRule'],
      recurrenceEndDate: json['recurrenceEndDate'] != null ? DateTime.parse(json['recurrenceEndDate']) : null,
      recurrenceGroupId: json['recurrenceGroupId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'startDateTime': startDateTime.toIso8601String(),
      'endDateTime': endDateTime.toIso8601String(),
      'courseName': courseName,
      'roomName': roomName,
      'isLocal': isLocal,
      'recurrenceRule': recurrenceRule,
      'recurrenceEndDate': recurrenceEndDate?.toIso8601String(),
      'recurrenceGroupId': recurrenceGroupId,
    };
  }
  // ----- for jsonEncode and jsonDecode

  Lesson copyWithDate(DateTime date) {
    final duration = endDateTime.difference(startDateTime);
    final newStart = DateTime(
      date.year,
      date.month,
      date.day,
      startDateTime.hour,
      startDateTime.minute,
    );
    return Lesson(
      name: name,
      startDateTime: newStart,
      endDateTime: newStart.add(duration),
      courseName: courseName,
      roomName: roomName,
      isLocal: isLocal,
      recurrenceRule: recurrenceRule,
      recurrenceEndDate: recurrenceEndDate,
      recurrenceGroupId: recurrenceGroupId,
    );
  }

  @override
  String toString() {
    return 'Lesson{name: $name, startDateTime: $startDateTime, endDateTime: $endDateTime, '
        'courseName: $courseName, roomName: $roomName, isLocal: $isLocal, '
        'recurrenceRule: $recurrenceRule, recurrenceGroupId: $recurrenceGroupId}';
  }
}
