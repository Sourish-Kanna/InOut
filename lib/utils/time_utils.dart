import 'package:intl/intl.dart';

import '../data/app_database.dart';

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

final _timeFmt = DateFormat('h:mm a');
String formatTime(DateTime t) => _timeFmt.format(t);

const dailyTarget = Duration(hours: 9);
const partialThreshold = Duration(hours: 6); // amber starts here

/// Total per day, keyed by LOCAL midnight of the clock_in date.
Map<DateTime, Duration> dailyTotals(Iterable<Session> sessions, DateTime now) {
  final map = <DateTime, Duration>{};
  for (final s in sessions) {
    final k = DateTime(s.clockIn.year, s.clockIn.month, s.clockIn.day);
    map[k] = (map[k] ?? Duration.zero) + sessionDuration(s, now);
  }
  return map;
}

enum DayStatus { none, met, partial, short, missed, inProgress }

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
  if (inProgress) return DayStatus.inProgress;
  if (total >= dailyTarget) return DayStatus.met;
  if (d == today) return DayStatus.none; // day not over, don't mark it red yet
  if (total >= partialThreshold) return DayStatus.partial;
  if (total > Duration.zero) return DayStatus.short;
  return DayStatus.missed;
}
