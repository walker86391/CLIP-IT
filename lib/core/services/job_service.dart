import '../bus/action_bus.dart';
import '../models/job.dart';

/// Job/workflow boundary.
///
/// Implementations own job execution; they listen for commands on the
/// ActionBus and emit [JobEvent]s. UI never calls this directly — it
/// dispatches commands.
abstract class JobService {
  /// Starts listening to commands on the bus. Idempotent.
  void start(ActionBus bus);

  /// Enqueue a job programmatically (used by JobManager facade + tests).
  Future<Job> enqueue(JobCreateCommand command);

  Future<void> cancel(String jobId);

  Future<void> retry(String jobId);
}
