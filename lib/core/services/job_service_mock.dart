import 'dart:async';
import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../bus/action_bus.dart';
import '../models/job.dart';
import '../models/pipeline_stage.dart';
import '../repos/job_repo.dart';
import '../utils/app_logger.dart';
import 'job_service.dart';

/// Timer-based pipeline simulator.
///
/// Listens for CreateJob/CancelJob/RetryJob on the ActionBus, walks the
/// [PipelineStage] list with timers, persists every change via [JobRepo],
/// and emits stage/progress events. Fully async and cancellable — no heavy
/// work, no main-isolate blocking.
final class JobServiceMock implements JobService {
  JobServiceMock(this._repo);

  final JobRepo _repo;
  final Uuid _uuid = const Uuid();

  final Map<String, Timer> _timers = {};
  final Map<String, _SimJob> _running = {};

  StreamSubscription<AppAction>? _sub;
  bool _started = false;

  /// Stops listening; pending simulations are cancelled via [cancel].
  void dispose() {
    _sub?.cancel();
    _started = false;
  }

  @override
  void start(ActionBus bus) {
    if (_started) return;
    _started = true;
    _bus = bus;
    _sub = bus.actionStream.listen(_onAction);
  }

  Future<void> _onAction(AppAction action) async {
    switch (action) {
      case CreateJob(:final command):
        await enqueue(command);
      case CancelJob(:final jobId):
        await cancel(jobId);
      case RetryJob(:final jobId):
        await retry(jobId);
    }
  }

  @override
  Future<Job> enqueue(JobCreateCommand command) async {
    final now = DateTime.now();
    final job = Job(
      id: _uuid.v4(),
      type: command.type,
      status: JobStatus.queued,
      progress: 0,
      currentStage: PipelineStage.input.label,
      createdAt: now,
      updatedAt: now,
      payloadJson: command.payload.isEmpty ? null : jsonEncode(command.payload),
    );
    await _repo.enqueue(job);
    _bus?.emit(JobEnqueued(job));

    // Small async hop so enqueue stays non-blocking even though the mock
    // starts immediately.
    unawaited(_run(job, delay: command.stageDelay));
    return job;
  }

  ActionBus? _bus;

  @override
  Future<void> cancel(String jobId) async {
    final timer = _timers.remove(jobId);
    timer?.cancel();
    _running.remove(jobId);

    final job = await _repo.get(jobId);
    if (job == null) return;
    if (job.status == JobStatus.completed ||
        job.status == JobStatus.cancelled) {
      return;
    }
    final cancelled = job.copyWith(
      status: JobStatus.cancelled,
      updatedAt: DateTime.now(),
    );
    await _repo.update(cancelled);
    _bus?.emit(JobCancelled(cancelled));
  }

  @override
  Future<void> retry(String jobId) async {
    final job = await _repo.get(jobId);
    if (job == null) return;

    // Cancel any live run first.
    await cancel(jobId);

    final fresh = job.copyWith(
      status: JobStatus.queued,
      progress: 0,
      currentStage: PipelineStage.input.label,
      error: null,
      resultJson: null,
      updatedAt: DateTime.now(),
    );
    await _repo.update(fresh);
    _bus?.emit(JobEnqueued(fresh));
    unawaited(_run(fresh, delay: _defaultDelay));
  }

  static const _defaultDelay = Duration(milliseconds: 700);

  Future<void> _run(Job job, {required Duration delay}) async {
    _running[job.id] = _SimJob(
      stageIndex: 0,
      delay: delay,
    );
    final started = job.copyWith(
      status: JobStatus.running,
      updatedAt: DateTime.now(),
    );
    await _repo.update(started);
    _bus?.emit(JobStarted(started));

    await _advance(job.id);
  }

  Future<void> _advance(String jobId) async {
    final sim = _running[jobId];
    if (sim == null) return; // Cancelled while waiting.

    final job = await _repo.get(jobId);
    if (job == null || job.status != JobStatus.running) return;

    final stages = PipelineStage.ordered;
    if (sim.stageIndex >= stages.length) {
      await _complete(job);
      return;
    }

    final stage = stages[sim.stageIndex];
    final progress = (sim.stageIndex + 1) / stages.length;

    final updated = job.copyWith(
      progress: progress,
      currentStage: stage.label,
      updatedAt: DateTime.now(),
    );
    await _repo.update(updated);
    _bus?.emit(JobProgress(jobId, stage.label, progress));

    _timers[jobId] = Timer(sim.delay, () {
      _running[jobId]?.let((s) => s.stageIndex += 1);
      unawaited(_advance(jobId));
    });
  }

  Future<void> _complete(Job job) async {
    _running.remove(job.id);
    _timers.remove(job.id);
    final done = job.copyWith(
      status: JobStatus.completed,
      progress: 1,
      currentStage: PipelineStage.output.label,
      resultJson: '{"simulated":true}',
      updatedAt: DateTime.now(),
    );
    await _repo.update(done);
    _bus?.emit(JobCompleted(done));
    AppLog.i('Job completed: ${job.id}');
  }
}

extension _Let<T> on T {
  R let<R>(R Function(T) block) => block(this);
}

/// Mutable simulation state per running job.
final class _SimJob {
  _SimJob({required this.stageIndex, required this.delay});

  int stageIndex;
  final Duration delay;
}
