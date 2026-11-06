import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clipit/core/db/app_database.dart';
import 'package:clipit/core/models/job.dart';
import 'package:clipit/core/models/project.dart';
import 'package:clipit/core/repos/job_repo.dart';
import 'package:clipit/core/repos/project_repo.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('Job: insert and read round-trips through JobRepo', () async {
    final repo = JobRepo(db);
    final time = DateTime.fromMillisecondsSinceEpoch(1767000000000);

    final job = Job(
      id: 'job-1',
      type: JobType.analyze,
      status: JobStatus.queued,
      progress: 0.25,
      currentStage: 'Input',
      createdAt: time,
      updatedAt: time,
      payloadJson: '{"key":"value"}',
    );

    await repo.enqueue(job);

    final read = await repo.get('job-1');
    expect(read, isNotNull);
    expect(read!.id, 'job-1');
    expect(read.type, JobType.analyze);
    expect(read.status, JobStatus.queued);
    expect(read.progress, 0.25);
    expect(read.currentStage, 'Input');
    expect(read.payloadJson, '{"key":"value"}');

    // findByStatus filter works on the enum column.
    final queued = await repo.findByStatus(JobStatus.queued);
    expect(queued.map((j) => j.id), contains('job-1'));
  });

  test('Project: insert and read round-trips through ProjectRepo', () async {
    final repo = ProjectRepo(db);
    final time = DateTime.fromMillisecondsSinceEpoch(1767000000000);

    await repo.create(
      Project(
        id: 'project-1',
        title: 'Launch Video',
        description: null,
        createdAt: time,
        updatedAt: time,
      ),
    );

    final read = await repo.get('project-1');
    expect(read, isNotNull);
    expect(read!.title, 'Launch Video');
    expect(read.description, isNull);
  });
}
