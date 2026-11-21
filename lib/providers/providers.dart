import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final openSessionProvider = StreamProvider<Session?>((ref) {
  return ref.watch(databaseProvider).watchOpenSession();
});

final todaySessionsProvider = StreamProvider<List<Session>>((ref) {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final end = start.add(const Duration(days: 1));
  return ref.watch(databaseProvider).watchSessionsBetween(start, end);
});

/// Pass the FIRST day of the month: DateTime(year, month).
final monthSessionsProvider = StreamProvider.family<List<Session>, DateTime>((
  ref,
  month,
) {
  final start = DateTime(month.year, month.month);
  final end = DateTime(month.year, month.month + 1);
  return ref.watch(databaseProvider).watchSessionsBetween(start, end);
});

/// Ticks every 30s so "live" hours refresh. Used on Home only.
final tickerProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 30), (_) => DateTime.now());
});
