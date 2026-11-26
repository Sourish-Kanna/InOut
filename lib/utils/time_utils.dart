import 'package:intl/intl.dart';

import '../data/app_database.dart';

const dailyTarget = Duration(hours: 8);
const partialThreshold = Duration(hours: 5); // amber starts here
enum DayStatus { none, met, partial, short, missed, inProgress }
final _timeFmt = DateFormat('h:mm a');

/// Duration of one session. Open session counts up to [now].
Duration sessionDuration(Session s, DateTime now) {
  if (s.clockOut == null) {
    final sameDay =
        s.clockIn.year == now.year &&
        s.clockIn.month == now.month &&
        s.clockIn.day == now.day;
    if (!sameDay)
      {return Duration.zero;} // stale open session, real length unknown
    return now.difference(s.clockIn).isNegative
        ? Duration.zero
        : now.difference(s.clockIn);
  }
  final d = s.clockOut!.difference(s.clockIn);
  return d.isNegative ? Duration.zero : d;
}

/// Sum exact durations first, floor to minutes only when displaying.
Duration totalFor(Iterable<Session> sessions, DateTime now) =>
    sessions.fold(Duration.zero, (sum, s) => sum + sessionDuration(s, now));

String formatHm(Duration d) => '${d.inHours}h ${d.inMinutes.remainder(60)}m';
String formatTime(DateTime t) => _timeFmt.format(t);

/// Total per day, keyed by LOCAL midnight of the clock_in date.
Map<DateTime, Duration> dailyTotals(Iterable<Session> sessions, DateTime now) {
  final map = <DateTime, Duration>{};
  for (final s in sessions) {
    final k = DateTime(s.clockIn.year, s.clockIn.month, s.clockIn.day);
    map[k] = (map[k] ?? Duration.zero) + sessionDuration(s, now);
  }
  return map;
}

DayStatus dayStatus({
  required DateTime day,
  required Duration total,
  required DateTime now,
  required bool inProgress, // open session started on this day
}) {
  final d = DateTime(day.year, day.month, day.day);
  final today = DateTime(now.year, now.month, now.day);

  if (d.weekday >= DateTime.saturday) return DayStatus.none; // weekends ignored
  if (d.isAfter(today)) return DayStatus.none;
  if (inProgress) return DayStatus.inProgress; // blue only while running
  if (total >= dailyTarget) return DayStatus.met;
  if (total >= partialThreshold) return DayStatus.partial;
  if (total > Duration.zero) return DayStatus.short;
  if (d == today) return DayStatus.none; // today, nothing logged yet
  return DayStatus.missed;
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class DaySummary {
  const DaySummary({
    required this.firstIn,
    required this.lastOut,
    required this.span,
  });

  final DateTime firstIn;
  final DateTime? lastOut; // null while still clocked in
  final Duration? span; // null for a stale open session (real length unknown)
}

/// Pass the sessions of ONE day.
DaySummary? daySummary(List<Session> sessions, DateTime now) {
  if (sessions.isEmpty) return null;

  final first = sessions
      .map((s) => s.clockIn)
      .reduce((a, b) => a.isBefore(b) ? a : b);
  final hasOpen = sessions.any((s) => s.clockOut == null);

  if (hasOpen) {
    // an open session from an earlier day would inflate the span, so skip it
    if (!_isSameDay(first, now)) {
      return DaySummary(firstIn: first, lastOut: null, span: null);
    }
    final d = now.difference(first);
    return DaySummary(
      firstIn: first,
      lastOut: null,
      span: d.isNegative ? Duration.zero : d,
    );
  }

  final last = sessions
      .map((s) => s.clockOut!)
      .reduce((a, b) => a.isAfter(b) ? a : b);
  return DaySummary(
    firstIn: first,
    lastOut: last,
    span: last.difference(first),
  );
}
