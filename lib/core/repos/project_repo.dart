import '../db/app_database.dart';
import '../models/project.dart';

/// CRUD for projects. UI/features never touch Drift directly.
class ProjectRepo {
  ProjectRepo(this._db);

  final AppDatabase _db;

  Future<void> create(Project project) => _db.projectsDao.upsert(ProjectRow(
        id: project.id,
        title: project.title,
        description: project.description,
        createdAt: project.createdAt,
        updatedAt: project.updatedAt,
      ));

  Future<Project?> get(String id) async {
    final row = await _db.projectsDao.findById(id);
    return row == null ? null : _toModel(row);
  }

  Future<List<Project>> list() async {
    final rows = await _db.projectsDao.listAll();
    return rows.map(_toModel).toList();
  }

  Future<void> update(Project project) =>
      create(project.copyWith(updatedAt: DateTime.now()));

  Future<void> delete(String id) => _db.projectsDao.deleteById(id);

  Project _toModel(ProjectRow row) => Project(
        id: row.id,
        title: row.title,
        description: row.description,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );
}
