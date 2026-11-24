import 'package:flutter_calendar_carousel/flutter_calendar_carousel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/app_database.dart';
import '../providers/providers.dart';
import '../utils/csv_export.dart';
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

  /// (background, text) per status, tuned for light and dark.
  (Color, Color)? _palette(DayStatus s, bool dark) => switch (s) {
    DayStatus.met =>
      dark
          ? (Colors.green.shade800, Colors.green.shade50)
          : (Colors.green.shade200, Colors.green.shade900),
    DayStatus.partial =>
      dark
          ? (Colors.amber.shade800, Colors.amber.shade50)
          : (Colors.amber.shade200, Colors.amber.shade900),
    DayStatus.short =>
      dark
          ? (Colors.red.shade800, Colors.red.shade50)
          : (Colors.red.shade200, Colors.red.shade900),
    DayStatus.missed =>
      dark
          ? (Colors.red.shade900.withValues(alpha: 0.35), Colors.red.shade200)
          : (Colors.red.shade50, Colors.red.shade400),
    DayStatus.inProgress =>
      dark
          ? (Colors.blue.shade800, Colors.blue.shade50)
          : (Colors.blue.shade200, Colors.blue.shade900),
    DayStatus.none => null,
  };

  Widget _legendChip(Color c, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      const SizedBox(width: 4),
      Text(label, style: Theme.of(context).textTheme.labelSmall),
    ],
  );

  Widget _legend(bool dark) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        _legendChip(_palette(DayStatus.met, dark)!.$1, '9h+'),
        _legendChip(_palette(DayStatus.partial, dark)!.$1, '6-9h'),
        _legendChip(_palette(DayStatus.short, dark)!.$1, 'under 6h'),
        _legendChip(_palette(DayStatus.missed, dark)!.$1, 'missed'),
        _legendChip(_palette(DayStatus.inProgress, dark)!.$1, 'in progress'),
      ],
    ),
  );

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
    final daySessions = sessions
        .where((s) => _sameDay(s.clockIn, _selected))
        .toList();

    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cellShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Today',
            onPressed: () => setState(() {
              _focused = DateTime.now();
              _selected = DateTime.now();
            }),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export CSV',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                final r = await exportCsv(ref.read(databaseProvider));
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      r == null
                          ? 'Nothing to export yet'
                          : 'Saved to ${r.displayPath}',
                    ),
                  ),
                );
              } catch (_) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Export failed')),
                );
              }
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          SizedBox(
            height: 460,
            child: CalendarCarousel<Duration>.month(
              selectedDate: _selected,
              focusedDate: _focused,
              firstDayOfWeek: CalendarWeekday.monday,
              header: const CalendarHeaderConfig(enableDatePicker: true),
              layout: const CalendarLayoutConfig(
                showOutsideDays: false,
                dayAspectRatio: 0.8, // taller cells: number + hours
                dayPadding: 2,
              ),
              theme: CalendarCarouselThemeData(
                day: CalendarDayStyle(
                  shape: cellShape,
                  alignment: const Alignment(0, -0.35),
                ),
                weekend: CalendarDayStyle(
                  textStyle: TextStyle(color: scheme.onSurfaceVariant),
                ),
                today: CalendarDayStyle(
                  shape: cellShape,
                  border: BorderSide(color: scheme.outline, width: 1.5),
                ),
                selected: CalendarDayStyle(
                  shape: cellShape,
                  border: BorderSide(color: scheme.primary, width: 2.5),
                ),
              ),
              // hours per day, passed to the calendar as the day's "event"
              eventsForDate: (date) {
                final t = totals[_key(date)];
                return (t == null || t == Duration.zero)
                    ? const <Duration>[]
                    : <Duration>[t];
              },
              markerBuilder: (context, day) => Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    formatHm(day.events.first),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: day.style.textStyle?.color,
                    ),
                  ),
                ),
              ),
              // status color per day
              dayStyleResolver: (context, day) {
                final k = _key(day.date);
                final status = dayStatus(
                  day: k,
                  total: totals[k] ?? Duration.zero,
                  now: now,
                  inProgress: openDays.contains(k),
                );
                final c = _palette(status, dark);
                if (c == null) return null;
                return CalendarDayStyle(
                  backgroundColor: c.$1,
                  textStyle: (day.style.textStyle ?? const TextStyle())
                      .copyWith(color: c.$2, fontWeight: FontWeight.w600),
                );
              },
              onDateSelected: (date, _) => setState(() {
                _selected = date;
                _focused = date;
              }),
              onPageChanged: (anchor) => setState(() => _focused = anchor),
            ),
          ),
          _legend(dark),
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
                leading: Icon(
                  s.clockOut == null
                      ? Icons.timelapse
                      : Icons.check_circle_outline,
                ),
                title: Text(
                  '${formatTime(s.clockIn)} → ${s.clockOut == null ? 'now' : formatTime(s.clockOut!)}',
                ),
                trailing: Text(formatHm(sessionDuration(s, now))),
                onTap: () =>
                    showSessionEditor(context, ref, day: s.clockIn, session: s),
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
