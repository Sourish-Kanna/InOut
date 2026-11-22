import 'package:flutter_calendar_carousel/flutter_calendar_carousel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/app_database.dart';
import '../providers/providers.dart';
import '../utils/time_utils.dart';
import '../widgets/session_editor.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();

  static DateTime _key(DateTime d) => DateTime(d.year, d.month, d.day);
  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  (Color bg, Color fg)? _colors(DayStatus s) => switch (s) {
        DayStatus.met => (Colors.green.shade200, Colors.green.shade900),
        DayStatus.partial => (Colors.amber.shade200, Colors.amber.shade900),
        DayStatus.short => (Colors.red.shade200, Colors.red.shade900),
        DayStatus.missed => (Colors.red.shade50, Colors.red.shade300),
        DayStatus.inProgress => (Colors.blue.shade200, Colors.blue.shade900),
        DayStatus.none => null,
      };

  @override
  Widget build(BuildContext context) {
    ref.watch(tickerProvider); // keeps open-session hours live
    final now = DateTime.now();
    final monthKey = DateTime(_focused.year, _focused.month);
    final sessions =
        ref.watch(monthSessionsProvider(monthKey)).value ?? const <Session>[];

    final totals = dailyTotals(sessions, now);
    final openDays = {
      for (final s in sessions)
        if (s.clockOut == null) _key(s.clockIn),
    };
    final monthTotal = totalFor(sessions, now);
    final daySessions =
        sessions.where((s) => _sameDay(s.clockIn, _selected)).toList();
    final scheme = Theme.of(context).colorScheme;

    Widget cell(DateTime date) {
      final k = _key(date);
      final total = totals[k] ?? Duration.zero;
      final status = dayStatus(
        day: k,
        total: total,
        now: now,
        inProgress: openDays.contains(k),
      );
      final c = _colors(status);
      final isWeekend = k.weekday >= DateTime.saturday;
      final fg = c?.$2 ??
          (isWeekend ? scheme.onSurfaceVariant : scheme.onSurface);
      final selected = _sameDay(k, _selected);
      final today = _sameDay(k, now);

      return Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: c?.$1,
          borderRadius: BorderRadius.circular(10),
          border: selected
              ? Border.all(color: scheme.primary, width: 2)
              : today
                  ? Border.all(color: scheme.outline)
                  : null,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${k.day}',
                  style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
              if (total > Duration.zero)
                Text(formatHm(total),
                    style: TextStyle(color: fg, fontSize: 10)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: ListView(
        children: [
          SizedBox(
            height: 420,
            child: CalendarCarousel<Object>.month(
              selectedDate: _selected,
              focusedDate: _focused,
              firstDayOfWeek: CalendarWeekday.monday,
              layout: const CalendarLayoutConfig(showOutsideDays: false),
              // base selected fill off, the cell draws its own selection border
              theme: const CalendarCarouselThemeData(
                selected: CalendarDayStyle(backgroundColor: Colors.transparent),
              ),
              dayBuilder: (context, day) => cell(day.date),
              onDateSelected: (date, _) => setState(() {
                _selected = date;
                _focused = date;
              }),
              onPageChanged: (anchor) => setState(() => _focused = anchor),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: const Text('Month total'),
              trailing: Text(
                formatHm(monthTotal),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              '${_selected.day}/${_selected.month}/${_selected.year}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (daySessions.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No sessions'),
            )
          else
            for (final s in daySessions)
              ListTile(
                onTap: () =>
                    showSessionEditor(context, ref, day: s.clockIn, session: s),
                leading: Icon(s.clockOut == null
                    ? Icons.timelapse
                    : Icons.check_circle_outline),
                title: Text(
                    '${formatTime(s.clockIn)} → ${s.clockOut == null ? 'now' : formatTime(s.clockOut!)}'),
                trailing: Text(formatHm(sessionDuration(s, now))),
              ),
              Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () => showSessionEditor(context, ref, day: _selected),
              icon: const Icon(Icons.add),
              label: const Text('Add session'),
            ),
          ),
        ],
      ),
    );
  }
}

