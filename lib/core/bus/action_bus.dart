import 'dart:async';

import '../models/job.dart';

/// Typed commands dispatched by the UI.
///
/// Widgets never run work themselves — they dispatch commands; the
/// JobService listens and acts. This is the UI → engine boundary.
sealed class AppAction {
  const AppAction();
}

final class CreateJob extends AppAction {
  const CreateJob(this.command);
  final JobCreateCommand command;
}

final class CancelJob extends AppAction {
  const CancelJob(this.jobId);
  final String jobId;
}

final class RetryJob extends AppAction {
  const RetryJob(this.jobId);
  final String jobId;
}

/// Typed events emitted by the job/workflow layer back to the UI.
///
/// Sequence for a successful run:
/// enqueued → started → progress* → completed.
sealed class JobEvent {
  const JobEvent();
}

final class JobEnqueued extends JobEvent {
  const JobEnqueued(this.job);
  final Job job;
}

final class JobStarted extends JobEvent {
  const JobStarted(this.job);
  final Job job;
}

final class JobProgress extends JobEvent {
  const JobProgress(this.jobId, this.stage, this.percent);
  final String jobId;
  final String stage;

  /// 0.0 – 1.0
  final double percent;
}

final class JobCompleted extends JobEvent {
  const JobCompleted(this.job);
  final Job job;
}

final class JobFailed extends JobEvent {
  const JobFailed(this.job, this.message);
  final Job job;
  final String message;
}

final class JobCancelled extends JobEvent {
  const JobCancelled(this.job);
  final Job job;
}

/// Action/event bus.
///
/// A singleton provider. UI dispatches [AppAction]s via [dispatch];
/// services subscribe with [onAction] and publish [JobEvent]s via [emit].
final class ActionBus {
  final StreamController<AppAction> _actions =
      StreamController.broadcast(sync: false);
  final StreamController<JobEvent> _events =
      StreamController.broadcast(sync: false);

  Stream<AppAction> get actionStream => _actions.stream;
  Stream<JobEvent> get eventStream => _events.stream;

  /// UI entry point: dispatch a typed command.
  void dispatch(AppAction action) => _actions.add(action);

  /// Services publish lifecycle events.
  void emit(JobEvent event) => _events.add(event);

  /// Convenience: subscribe to actions for a specific type.
  Stream<T> onAction<T extends AppAction>() =>
      _actions.stream.where((a) => a is T).cast<T>();

  Future<void> dispose() async {
    await _actions.close();
    await _events.close();
  }
}
