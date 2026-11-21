import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get clockIn => dateTime()();
  DateTimeColumn get clockOut =>
      dateTime().nullable()(); // null = still clocked in
}

@DriftDatabase(tables: [Sessions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'punch_clock'));

  @override
  int get schemaVersion => 1;

  /// The session with no clock_out, or null.
  Stream<Session?> watchOpenSession() {
    return (select(sessions)
          ..where((s) => s.clockOut.isNull())
          ..limit(1))
        .watchSingleOrNull();
  }

  /// Sessions whose clock_in falls in [start, end).
  Stream<List<Session>> watchSessionsBetween(DateTime start, DateTime end) {
    return (select(sessions)
          ..where(
            (s) =>
                s.clockIn.isBiggerOrEqualValue(start) &
                s.clockIn.isSmallerThanValue(end),
          )
          ..orderBy([(s) => OrderingTerm.asc(s.clockIn)]))
        .watch();
  }

  Future<void> punchIn() async {
    final open = await (select(
      sessions,
    )..where((s) => s.clockOut.isNull())).get();
    if (open.isNotEmpty) return; // already clocked in
    await into(sessions)
        .insert(SessionsCompanion.insert(clockIn: DateTime.now()));
  }

  Future<void> punchOut() async {
    await (update(sessions)..where((s) => s.clockOut.isNull())).write(
      SessionsCompanion(clockOut: Value(DateTime.now())),
    );
  }
}
