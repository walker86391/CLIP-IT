import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/job.dart';

part 'app_database.g.dart';

// ── Tables ────────────────────────────────────────────────────────────────
// Row classes are suffixed `Row` to avoid clashing with domain models in
// core/models. Repos translate Row ↔ domain model at the boundary.

@DataClassName('UserRow')
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get email => text().withLength(min: 1, max: 320)();
  TextColumn get displayName => text().nullable()();
  TextColumn get avatarUrl => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ProjectRow')
class Projects extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('JobRow')
class Jobs extends Table {
  TextColumn get id => text()();
  TextColumn get type => textEnum<JobType>()();
  TextColumn get status => textEnum<JobStatus>()();
  RealColumn get progress => real().withDefault(const Constant(0.0))();
  TextColumn get currentStage => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get payloadJson => text().nullable()();
  TextColumn get resultJson => text().nullable()();
  TextColumn get error => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SettingRow')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {key};
}

@DataClassName('FeatureFlagRow')
class FeatureFlags extends Table {
  TextColumn get key => text()();
  BoolColumn get enabled => boolean().withDefault(const Constant(false))();
  TextColumn get description => text().nullable()();

  @override
  Set<Column> get primaryKey => {key};
}

// ── DAOs ──────────────────────────────────────────────────────────────────

@DriftAccessor(tables: [Jobs])
class JobsDao extends DatabaseAccessor<AppDatabase> with _$JobsDaoMixin {
  JobsDao(super.db);

  /// Insert or replace a job row (upsert by primary key).
  Future<void> upsert(JobRow row) =>
      into(jobs).insertOnConflictUpdate(row);

  Future<void> updateRow(JobRow row) => update(jobs).replace(row);

  Future<JobRow?> findById(String id) =>
      (select(jobs)..where((j) => j.id.equals(id))).getSingleOrNull();

  Future<List<JobRow>> findByStatus(JobStatus status, {int limit = 100}) =>
      (select(jobs)
            ..where((j) => j.status.equalsValue(status))
            ..orderBy([(j) => OrderingTerm.desc(j.updatedAt)])
            ..limit(limit))
          .get();

  Future<List<JobRow>> listRecent({int limit = 50}) =>
      (select(jobs)
            ..orderBy([(j) => OrderingTerm.desc(j.createdAt)])
            ..limit(limit))
          .get();

  /// Live stream of recent jobs for reactive UI.
  Stream<List<JobRow>> watchRecent({int limit = 50}) =>
      (select(jobs)
            ..orderBy([(j) => OrderingTerm.desc(j.createdAt)])
            ..limit(limit))
          .watch();

  Future<int> deleteById(String id) =>
      (delete(jobs)..where((j) => j.id.equals(id))).go();
}

@DriftAccessor(tables: [Projects])
class ProjectsDao extends DatabaseAccessor<AppDatabase>
    with _$ProjectsDaoMixin {
  ProjectsDao(super.db);

  Future<void> upsert(ProjectRow row) =>
      into(projects).insertOnConflictUpdate(row);

  Future<ProjectRow?> findById(String id) =>
      (select(projects)..where((pr) => pr.id.equals(id))).getSingleOrNull();

  Future<List<ProjectRow>> listAll() =>
      (select(projects)..orderBy([(pr) => OrderingTerm.desc(pr.updatedAt)]))
          .get();

  Future<int> deleteById(String id) =>
      (delete(projects)..where((pr) => pr.id.equals(id))).go();
}

@DriftAccessor(tables: [Settings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  Future<String?> read(String key) async {
    final row = await (select(settings)
          ..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> write(String key, String? value) =>
      into(settings).insertOnConflictUpdate(SettingRow(
        key: key,
        value: value,
        updatedAt: DateTime.now(),
      ));
}

// ── Database ──────────────────────────────────────────────────────────────

@DriftDatabase(
  tables: [Users, Projects, Jobs, Settings, FeatureFlags],
  daos: [JobsDao, ProjectsDao, SettingsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase({QueryExecutor? executor}) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // Step 0: schema v1. Add forward-only migrations here as `to`
          // increases, e.g.:
          // if (from < 2) { await m.addColumn(jobs, jobs.someColumn); }
        },
        beforeOpen: (details) async {
          // WAL for durability + concurrent readers.
          await customStatement('PRAGMA journal_mode = WAL;');
          await customStatement('PRAGMA foreign_keys = ON;');
        },
      );

  static QueryExecutor _openConnection() => LazyDatabase(() async {
        final dir = await getApplicationSupportDirectory();
        final file = File(p.join(dir.path, 'clipit.db'));
        // Run the database on a background isolate: heavy work never blocks
        // the UI thread.
        return NativeDatabase.createInBackground(file);
      });
}
