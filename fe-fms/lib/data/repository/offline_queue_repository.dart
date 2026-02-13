import 'package:fms/core/database/offline_database.dart';
import 'package:fms/data/models/offline_queue_item.dart';

class OfflineQueueRepository {
  Future<int> enqueue(OfflineQueueItem item) async {
    final db = await OfflineDatabase.instance.database;
    return db.insert('offline_queue', item.toMap());
  }

  Future<List<OfflineQueueItem>> getPendingItems() async {
    final db = await OfflineDatabase.instance.database;
    final rows = await db.query(
      'offline_queue',
      where: "status = ?",
      whereArgs: ['pending'],
      orderBy: 'created_at ASC',
    );
    return rows.map((r) => OfflineQueueItem.fromMap(r)).toList();
  }

  Future<void> markSyncing(int id) async {
    final db = await OfflineDatabase.instance.database;
    await db.update(
      'offline_queue',
      {'status': 'syncing'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(int id) async {
    final db = await OfflineDatabase.instance.database;
    await db.delete('offline_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> hasQueuedActionForJob(int jobId) async {
    final db = await OfflineDatabase.instance.database;
    final result = await db.query(
      'offline_queue',
      where: 'job_id = ?',
      whereArgs: [jobId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<List<OfflineQueueItem>> getAllItems() async {
    final db = await OfflineDatabase.instance.database;
    final rows = await db.query('offline_queue', orderBy: 'created_at ASC');
    return rows.map((r) => OfflineQueueItem.fromMap(r)).toList();
  }

  Future<void> resetSyncingToPending() async {
    final db = await OfflineDatabase.instance.database;
    await db.update(
      'offline_queue',
      {'status': 'pending'},
      where: "status = ?",
      whereArgs: ['syncing'],
    );
  }

  Future<void> deleteAll() async {
    final db = await OfflineDatabase.instance.database;
    await db.delete('offline_queue');
  }
}
