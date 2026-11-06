import '../db/app_database.dart';
import '../models/job.dart';

/// Persistence for jobs. JobServiceMock writes every lifecycle change here
/// so history survives restarts.
class JobRepo {
  JobRepo(this._db);

  final AppDatabase _db;

  /// Insert or replace (upsert by id).
  Future<void> enqueue(Job job) => _db.jobsDao.upsert(_toRow(job));

  /// Alias for enqueue with clearer intent for updates.
  Future<void> update(Job job) => _db.jobsDao.upsert(_toRow(job));

  Future<Job?> get(String id) async {
    final row = await _db.jobsDao.findById(id);
    return row == null ? null : _toModel(row);
  }

  Future<List<Job>> findByStatus(JobStatus status) async {
    final rows = await _db.jobsDao.findByStatus(status);
    return rows.map(_toModel).toList();
  }

  Future<List<Job>> listRecent({int limit = 50}) async {
    final rows = await _db.jobsDao.listRecent(limit: limit);
    return rows.map(_toModel).toList();
  }

  /// Reactive stream of recent jobs (drives job lists / history).
  Stream<List<Job>> watchRecent({int limit = 50}) =>
      _db.jobsDao.watchRecent(limit: limit).map(
            (rows) => rows.map(_toModel).toList(),
          );

  Future<void> delete(String id) => _db.jobsDao.deleteById(id);

  JobRow _toRow(Job job) => JobRow(
        id: job.id,
        type: job.type,
        status: job.status,
        progress: job.progress,
        currentStage: job.currentStage,
        createdAt: job.createdAt,
        updatedAt: job.updatedAt,
        payloadJson: job.payloadJson,
        resultJson: job.resultJson,
        error: job.error,
      );

  Job _toModel(JobRow row) => Job(
        id: row.id,
        type: row.type,
        status: row.status,
        progress: row.progress,
        currentStage: row.currentStage,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        payloadJson: row.payloadJson,
        resultJson: row.resultJson,
        error: row.error,
      );
}
