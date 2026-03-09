// thanks to claude for migration file from objbox </3
import 'package:drift/drift.dart';
import 'package:unipi_orario/entities/lesson.dart'; // exports LessonModel

// Web-only import (conditionally imported via the stub on native)
import 'app_database_web.dart' if (dart.library.io) 'app_database_stub.dart' as platform;

part 'app_database.g.dart';

class Lessons extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();
  TextColumn get courseName => text().nullable()();
  TextColumn get roomName => text()();
  BoolColumn get isLocal => boolean().withDefault(const Constant(false))();

  DateTimeColumn get startDateTime => dateTime()();
  DateTimeColumn get endDateTime => dateTime()();

  TextColumn get recurrenceRule => text().nullable()();
  DateTimeColumn get recurrenceEndDate => dateTime().nullable()();
  TextColumn get recurrenceGroupId => text().nullable()();
}

// ---------------------------------------------------------------------------
// Database class
// ---------------------------------------------------------------------------

@DriftDatabase(tables: [Lessons])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // ---------------------------------------------------------------------------
  // Helpers that mirror the ObjectBox query patterns used across the app.
  // All methods return Drift's generated [Lesson] row type.
  // Call .toModel() on results to get [LessonModel].
  // ---------------------------------------------------------------------------

  /// Inserts a lesson and returns its new id.
  Future<int> insertLesson(LessonsCompanion lesson) => into(lessons).insert(lesson);

  /// Inserts many remote lessons at once (replaces putManyAsync).
  Future<void> insertManyLessons(List<LessonsCompanion> rows) => batch((b) => b.insertAll(lessons, rows));

  /// Deletes a single lesson by id.
  Future<void> deleteLessonById(int id) => (delete(lessons)..where((t) => t.id.equals(id))).go();

  /// Deletes all lessons belonging to a recurrence series.
  Future<void> deleteLessonSeries(String groupId) => (delete(lessons)..where((t) => t.recurrenceGroupId.equals(groupId))).go();

  /// Removes all non-local (remote) lessons — used when refreshing from API.
  Future<void> deleteAllRemoteLessons() => (delete(lessons)..where((t) => t.isLocal.equals(false))).go();

  /// Returns lessons whose startDateTime falls within [start, end].
  Future<List<Lesson>> getLessonsInRange(DateTime start, DateTime end) => (select(lessons)
        ..where((t) => t.startDateTime.isBiggerOrEqualValue(start) & t.startDateTime.isSmallerOrEqualValue(end))
        ..orderBy([(t) => OrderingTerm.asc(t.startDateTime)]))
      .get();

  /// Returns all local template lessons (isLocal == true).
  Future<List<Lesson>> getLocalTemplates() => (select(lessons)..where((t) => t.isLocal.equals(true))).get();

  /// Returns all lessons regardless of date.
  Future<List<Lesson>> getAllLessons() => select(lessons).get();

  /// Returns upcoming lessons (startDateTime >= yesterday) ordered by date,
  /// limited to [limit] rows.
  Future<List<Lesson>> getUpcomingLessons({int limit = 50}) => (select(lessons)
        ..where((t) => t.startDateTime.isBiggerOrEqualValue(DateTime.now().subtract(const Duration(days: 1))))
        ..orderBy([(t) => OrderingTerm.asc(t.startDateTime)])
        ..limit(limit))
      .get();
}

// ---------------------------------------------------------------------------
// Conversion helpers — Drift Row <-> LessonModel
// ---------------------------------------------------------------------------

extension LessonRowConversion on Lesson {
  /// Convert a Drift-generated [Lesson] row to the app's [LessonModel].
  LessonModel toModel() => LessonModel(
        id: id,
        name: name,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        courseName: courseName,
        roomName: roomName,
        isLocal: isLocal,
        recurrenceRule: recurrenceRule,
        recurrenceEndDate: recurrenceEndDate,
        recurrenceGroupId: recurrenceGroupId,
      );
}

extension LessonModelConversion on LessonModel {
  /// Convert a [LessonModel] to a Drift [LessonsCompanion] for insert/update.
  LessonsCompanion toCompanion() => LessonsCompanion.insert(
        name: name,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        courseName: Value(courseName),
        roomName: roomName,
        isLocal: Value(isLocal),
        recurrenceRule: Value(recurrenceRule),
        recurrenceEndDate: Value(recurrenceEndDate),
        recurrenceGroupId: Value(recurrenceGroupId),
      );
}

// ---------------------------------------------------------------------------
// Platform-specific connection factory
// ---------------------------------------------------------------------------

QueryExecutor _openConnection() => platform.openConnection('lessons.db');
