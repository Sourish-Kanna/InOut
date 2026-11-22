import 'dart:io';

import 'package:intl/intl.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../data/app_database.dart';

final _mediaStore = MediaStore();

enum ExportResult { empty, saved, failed }

String buildCsv(List<Session> sessions) {
  final d = DateFormat('yyyy-MM-dd');
  final t = DateFormat('HH:mm');
  final b = StringBuffer('date,clock_in,clock_out,minutes\r\n');
  for (final s in sessions) {
    final out = s.clockOut;
    final outStr = out == null ? '' : t.format(out);
    final mins = out == null ? '' : '${out.difference(s.clockIn).inMinutes}';
    b.write('${d.format(s.clockIn)},${t.format(s.clockIn)},$outStr,$mins\r\n');
  }
  return b.toString();
}

/// Saves to Downloads/InOut/inout_YYYYMMDD_HHmm.csv
Future<ExportResult> exportCsv(AppDatabase db) async {
  try {
    final sessions = await db.getAllSessions();
    if (sessions.isEmpty) return ExportResult.empty;

    final name =
        'inout_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';
    final tmp = File('${(await getTemporaryDirectory()).path}/$name');
    await tmp.writeAsString(buildCsv(sessions));

    final info = await _mediaStore.saveFile(
      tempFilePath: tmp.path,
      dirType: DirType.download,
      dirName: DirName.download,
    );
    return info == null ? ExportResult.failed : ExportResult.saved;
  } catch (_) {
    return ExportResult.failed;
  }
}
