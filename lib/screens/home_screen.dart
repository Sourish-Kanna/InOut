import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:percent_indicator/percent_indicator.dart';

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

    final progress = (total.inMinutes / dailyTarget.inMinutes)
        .clamp(0.0, 1.0)
        .toDouble();
    final remaining = dailyTarget - total;

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
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('EEEE, d MMM').format(now),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 12),
                      CircularPercentIndicator(
                        radius: 85, // 170 px wide
                        lineWidth: 12,
                        percent: progress, // 0.0 to 1.0, already clamped
                        animation: true,
                        animateFromLastPercent: true,
                        animationDuration: 600,
                        circularStrokeCap: CircularStrokeCap.round,
                        backgroundColor: scheme.surfaceContainerHighest,
                        progressColor: progress >= 1
                            ? Colors.green
                            : scheme.secondary,
                        center: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              formatHm(total),
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            Text(
                              remaining > Duration.zero
                                  ? '${formatHm(remaining)} left'
                                  : 'Target met',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      if (open != null && !staleOpen) ...[
                        const SizedBox(height: 12),
                        Text('In since ${formatTime(open.clockIn)}'),
                      ],
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
                  backgroundColor: isIn ? scheme.secondary : scheme.primary,
                  foregroundColor: isIn ? scheme.onSecondary : scheme.onPrimary,
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
                            leading: Icon(
                              s.clockOut == null
                                  ? Icons.timelapse
                                  : Icons.check_circle_outline,
                            ),
                            title: Text('${formatTime(s.clockIn)} → $out'),
                            trailing: Text(formatHm(sessionDuration(s, now))),
                            onTap: () => showSessionEditor(
                              context,
                              ref,
                              day: s.clockIn,
                              session: s,
                            ),
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
