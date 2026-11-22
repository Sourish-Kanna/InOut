import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

// dart run build_runner build

class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get clockIn => dateTime()();
  DateTimeColumn get clockOut =>
      dateTime().nullable()(); // null = still clocked in
}

class SessionException implements Exception {
  SessionException(this.message);
  final String message;
}

/// Open session from an earlier day: user must set the real clock-out.
class StaleSessionException extends SessionException {
  StaleSessionException()
    : super('Session started on an earlier day. Set the real clock-out time.');
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

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

  Future<void> punchIn() => transaction(() async {
    final open = await (select(
      sessions,
    )..where((s) => s.clockOut.isNull())).get();
    if (open.isNotEmpty) return; // already clocked in
    final now = DateTime.now();
    await _validate(now, null); // catches device clock set back
    await into(sessions).insert(SessionsCompanion.insert(clockIn: now));
  });

  Future<void> punchOut() => transaction(() async {
    final open =
        await (select(sessions)
              ..where((s) => s.clockOut.isNull())
              ..limit(1))
            .getSingleOrNull();
    if (open == null) return;
    final now = DateTime.now();
    if (!_sameDay(open.clockIn, now)) throw StaleSessionException();
    if (!now.isAfter(open.clockIn)) {
      throw SessionException('Device time is before the clock-in time');
    }
    await (update(sessions)..where((s) => s.id.equals(open.id))).write(
      SessionsCompanion(clockOut: Value(now)),
    );
  });

  Future<void> addSession(DateTime start, DateTime end) =>
      transaction(() async {
        await _validate(start, end);
        await into(sessions).insert(
          SessionsCompanion.insert(clockIn: start, clockOut: Value(end)),
        );
      });

  /// [end] null is allowed only while no other session is open.
  Future<void> updateSession(int id, DateTime start, DateTime? end) =>
      transaction(() async {
        await _validate(start, end, excludeId: id);
        await (update(sessions)..where((s) => s.id.equals(id))).write(
          SessionsCompanion(clockIn: Value(start), clockOut: Value(end)),
        );
      });

  Future<void> deleteSession(int id) =>
      (delete(sessions)..where((s) => s.id.equals(id))).go();

  Future<void> _validate(
    DateTime start,
    DateTime? end, {
    int? excludeId,
  }) async {
    final now = DateTime.now();
    if (start.isAfter(now)) throw SessionException('Clock-in is in the future');
    if (end != null) {
      if (!end.isAfter(start)) {
        throw SessionException('Clock-out must be after clock-in');
      }
      if (end.isAfter(now))
        {throw SessionException('Clock-out is in the future');}
      if (!_sameDay(start, end)) {
        throw SessionException('Session must end on the same day');
      }
    } else {
      // open session: make sure no OTHER session is already open
      final others =
          await (select(sessions)
                ..where((s) => s.clockOut.isNull())
                ..where(
                  (s) => excludeId == null
                      ? const Constant(true)
                      : s.id.equals(excludeId).not(),
                ))
              .get();
      if (others.isNotEmpty) throw SessionException('Already clocked in');
    }

    // overlap: other.in < newEnd AND (other.out IS NULL OR other.out > newStart)
    final endBound = end ?? DateTime(9999);
    final overlapping =
        await (select(sessions)
              ..where(
                (s) =>
                    s.clockIn.isSmallerThanValue(endBound) &
                    (s.clockOut.isNull() | s.clockOut.isBiggerThanValue(start)),
              )
              ..where(
                (s) => excludeId == null
                    ? const Constant(true)
                    : s.id.equals(excludeId).not(),
              ))
            .get();
    if (overlapping.isNotEmpty) {
      throw SessionException('Overlaps another session');
    }
  }
}
