import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/app_database.dart';
import '../providers/providers.dart';
import '../utils/time_utils.dart';
import '../widgets/session_editor.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(tickerProvider); // rebuilds every 30s so live hours update
    final now = DateTime.now();
    final db = ref.read(databaseProvider);
    final open = ref.watch(openSessionProvider).value;
    final sessions =
        ref.watch(todaySessionsProvider).value ?? const <Session>[];

    final isIn = open != null;
    final total = totalFor(sessions, now);
    final todayStart = DateTime(now.year, now.month, now.day);
    final staleOpen = open != null && open.clockIn.isBefore(todayStart);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('InOut')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (staleOpen)
                Card(
                  color: scheme.errorContainer,
                  child: ListTile(
                    leading: const Icon(Icons.warning_amber),
                    title: const Text('Still clocked in from an earlier day'),
                    subtitle: Text(
                      'Since ${formatTime(open.clockIn)} on '
                      '${open.clockIn.day}/${open.clockIn.month}',
                    ),
                  ),
                ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Text(
                        'Today',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatHm(total),
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  try {
                    isIn ? await db.punchOut() : await db.punchIn();
                  } on StaleSessionException catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(e.message)));
                    showSessionEditor(
                      context,
                      ref,
                      day: open!.clockIn,
                      session: open,
                    );
                  } on SessionException catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(e.message)));
                  }
                },
                icon: Icon(isIn ? Icons.logout : Icons.login),
                label: Text(isIn ? 'Clock Out' : 'Clock In'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(64),
                  textStyle: const TextStyle(fontSize: 20),
                  backgroundColor: isIn ? scheme.tertiary : scheme.primary,
                  foregroundColor: isIn ? scheme.onTertiary : scheme.onPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text('Sessions', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Expanded(
                child: sessions.isEmpty
                    ? const Center(child: Text('No sessions today'))
                    : ListView.separated(
                        itemCount: sessions.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final s = sessions[i];
                          final out = s.clockOut == null
                              ? 'now'
                              : formatTime(s.clockOut!);
                          return ListTile(
                            onTap: () => showSessionEditor(
                              context,
                              ref,
                              day: s.clockIn,
                              session: s,
                            ),
                            leading: Icon(
                              s.clockOut == null
                                  ? Icons.timelapse
                                  : Icons.check_circle_outline,
                            ),
                            title: Text('${formatTime(s.clockIn)} → $out'),
                            trailing: Text(formatHm(sessionDuration(s, now))),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
