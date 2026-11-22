import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/app_database.dart';
import '../providers/providers.dart';

/// Add (session == null) or edit/delete a session. [day] decides the date.
Future<void> showSessionEditor(
  BuildContext context,
  WidgetRef ref, {
  required DateTime day,
  Session? session,
}) {
  final db = ref.read(databaseProvider);
  final isNew = session == null;
  final base = DateTime(day.year, day.month, day.day);

  TimeOfDay inT = TimeOfDay.fromDateTime(
    session?.clockIn ?? base.add(const Duration(hours: 9)),
  );
  TimeOfDay? outT = session?.clockOut != null
      ? TimeOfDay.fromDateTime(session!.clockOut!)
      : (isNew
            ? const TimeOfDay(hour: 18, minute: 0)
            : null); // null = still in
  String? error;

  DateTime at(TimeOfDay t) =>
      DateTime(base.year, base.month, base.day, t.hour, t.minute);

  return showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        Future<void> pick(bool isIn) async {
          final t = await showTimePicker(
            context: ctx,
            initialTime: (isIn ? inT : outT) ?? TimeOfDay.now(),
          );
          if (t == null) return;
          setState(() {
            error = null;
            isIn ? inT = t : outT = t;
          });
        }

        Future<void> save() async {
          try {
            if (isNew) {
              await db.addSession(at(inT), at(outT!));
            } else {
              await db.updateSession(
                session.id,
                at(inT),
                outT == null ? null : at(outT!),
              );
            }
            if (ctx.mounted) Navigator.of(ctx).pop();
          } on SessionException catch (e) {
            setState(() => error = e.message);
          }
        }

        Future<void> delete() async {
          final ok = await showDialog<bool>(
            context: ctx,
            builder: (c) => AlertDialog(
              title: const Text('Delete session?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(c).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(c).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
          if (ok == true) {
            await db.deleteSession(session!.id);
            if (ctx.mounted) Navigator.of(ctx).pop();
          }
        }

        return AlertDialog(
          title: Text(isNew ? 'Add session' : 'Edit session'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${base.day}/${base.month}/${base.year}'),
              ListTile(
                title: const Text('In'),
                trailing: Text(inT.format(ctx)),
                onTap: () => pick(true),
              ),
              ListTile(
                title: const Text('Out'),
                trailing: Text(outT?.format(ctx) ?? 'still in'),
                onTap: () => pick(false),
              ),
              if (error != null)
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                ),
            ],
          ),
          actions: [
            if (!isNew)
              TextButton(onPressed: delete, child: const Text('Delete')),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(onPressed: save, child: const Text('Save')),
          ],
        );
      },
    ),
  );
}
