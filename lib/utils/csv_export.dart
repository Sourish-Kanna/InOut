import 'dart:developer' as dev;
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../data/app_database.dart';

const _folderName = 'InOut';

class ExportResult {
  const ExportResult({required this.file, required this.displayPath});
  final File file;
  final String displayPath;
}

Future<Directory> _exportDirectory() async {
  Directory? base;

  if (Platform.isAndroid) {
    final publicDownloads = Directory('/storage/emulated/0/Download');
    if (await publicDownloads.exists()) {
      base = publicDownloads;
    } else {
      try {
        base = await getDownloadsDirectory();
      } catch (_) {}
      base ??= await getExternalStorageDirectory();
    }
  } else if (Platform.isIOS) {
    base = await getApplicationDocumentsDirectory();
  } else {
    try {
      base = await getDownloadsDirectory();
    } catch (_) {}
    base ??= await getApplicationDocumentsDirectory();
  }

  if (base == null) {
    throw const FileSystemException('Could not locate storage directory.');
  }

  final dir = Directory('${base.path}/$_folderName');
  if (!await dir.exists()) await dir.create(recursive: true);
  return dir;
}

/// Returns null when there is nothing to export. Throws on write failure.
Future<ExportResult?> exportCsv(AppDatabase db) async {
  try {
    final sessions = await db.getAllSessions();
    if (sessions.isEmpty) return null;

    final dateFmt = DateFormat('yyyy-MM-dd');
    final dayFmt = DateFormat('EEE');
    final timeFmt = DateFormat('HH:mm');

    final rows = <List<dynamic>>[
      [
        'ID',
        'Date',
        'Day',
        'Clock In',
        'Clock Out',
        'Minutes',
        'Hours',
        'Status',
      ],
    ];

    for (final s in sessions) {
      final out = s.clockOut;
      final mins = out?.difference(s.clockIn).inMinutes;
      rows.add([
        s.id,
        dateFmt.format(s.clockIn),
        dayFmt.format(s.clockIn),
        timeFmt.format(s.clockIn),
        out == null ? '' : timeFmt.format(out),
        mins ?? '',
        mins == null ? '' : (mins / 60).toStringAsFixed(2),
        out == null ? 'Open' : 'Completed',
      ]);
    }

    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'inout_sessions_$stamp.csv';

    final dir = await _exportDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(csv.encode(rows));

    dev.log('CSV export saved to ${file.path}', name: 'InOut');

    final displayLocation = Platform.isIOS
        ? 'Documents/$_folderName/$fileName'
        : 'Downloads/$_folderName/$fileName';

    return ExportResult(
      file: file,
      displayPath: displayLocation,
    );
  } catch (e, st) {
    dev.log('CSV export failed', error: e, stackTrace: st, name: 'InOut');
    rethrow;
  }
}
