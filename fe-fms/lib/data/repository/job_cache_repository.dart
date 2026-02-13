import 'dart:convert';

import 'package:fms/core/database/offline_database.dart';
import 'package:fms/data/models/response/get_job_ongoing_response_model.dart';

class JobCacheRepository {
  Future<void> cacheOngoingJobs(List<Data> jobs) async {
    final db = await OfflineDatabase.instance.database;
    final batch = db.batch();
    batch.delete('cached_jobs');
    final now = DateTime.now().toIso8601String();
    for (final job in jobs) {
      batch.insert('cached_jobs', {
        'job_id': job.jobId,
        'job_data': jsonEncode(job.toMap()),
        'cached_at': now,
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<Data>> getCachedOngoingJobs() async {
    final db = await OfflineDatabase.instance.database;
    final rows = await db.query('cached_jobs');
    return rows.map((r) {
      final map = jsonDecode(r['job_data'] as String) as Map<String, dynamic>;
      return Data.fromMap(map);
    }).toList();
  }

  Future<void> removeJob(int jobId) async {
    final db = await OfflineDatabase.instance.database;
    await db.delete('cached_jobs', where: 'job_id = ?', whereArgs: [jobId]);
  }

  Future<void> clearAll() async {
    final db = await OfflineDatabase.instance.database;
    await db.delete('cached_jobs');
  }
}
