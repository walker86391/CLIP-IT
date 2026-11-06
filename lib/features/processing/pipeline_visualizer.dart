import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/job.dart';
import '../../core/models/pipeline_stage.dart';
import '../../core/providers/core_providers.dart';
import '../../ui/tokens/colors.dart';
import '../../ui/tokens/spacing.dart';
import '../../ui/tokens/typography.dart';

/// Aggregate run state rendered by the visualizer header.
enum PipelineRunState { waiting, processing, completed, failed, cancelled }

extension PipelineRunStateX on PipelineRunState {
  String get label => switch (this) {
        PipelineRunState.waiting => 'Waiting',
        PipelineRunState.processing => 'Processing',
        PipelineRunState.completed => 'Completed',
        PipelineRunState.failed => 'Failed',
        PipelineRunState.cancelled => 'Cancelled',
      };

  Color get color => switch (this) {
        PipelineRunState.waiting => AppColors.textTertiary,
        PipelineRunState.processing => AppColors.accent,
        PipelineRunState.completed => AppColors.success,
        PipelineRunState.failed => AppColors.danger,
        PipelineRunState.cancelled => AppColors.warning,
      };
}

/// Live pipeline view for the most relevant job.
///
/// Subscribes to the job stream (drift watch fed by JobServiceMock events)
/// and renders the 13-stage pipeline with per-stage state. Step 0: driven by
/// the simulated engine; the Processing page will host this once
/// implemented.
class PipelineVisualizer extends ConsumerWidget {
  const PipelineVisualizer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(recentJobsProvider);

    return jobs.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (list) {
        final job = _pickJob(list);
        final runState = _runStateOf(job);
        final stageIndex = _stageIndexOf(job);

        return Container(
          padding: const EdgeInsets.all(Spacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.rMd,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _Header(runState: runState, job: job),
              const SizedBox(height: Spacing.md),
              for (final stage in PipelineStage.ordered)
                _StageRow(
                  stage: stage,
                  state: _stageState(
                    stage,
                    index: PipelineStage.ordered.indexOf(stage),
                    currentIndex: stageIndex,
                    runState: runState,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Most recent running job → queued → most recent overall.
  static Job? _pickJob(List<Job> jobs) {
    final running = jobs.firstWhereOrNull((j) => j.status == JobStatus.running);
    if (running != null) return running;
    final queued = jobs.firstWhereOrNull((j) => j.status == JobStatus.queued);
    if (queued != null) return queued;

    Job? latest;
    for (final j in jobs) {
      if (latest == null || j.updatedAt.isAfter(latest.updatedAt)) {
        latest = j;
      }
    }
    return latest;
  }

  static PipelineRunState _runStateOf(Job? job) {
    if (job == null) return PipelineRunState.waiting;
    return switch (job.status) {
      JobStatus.queued => PipelineRunState.waiting,
      JobStatus.running => PipelineRunState.processing,
      JobStatus.completed => PipelineRunState.completed,
      JobStatus.failed => PipelineRunState.failed,
      JobStatus.cancelled => PipelineRunState.cancelled,
    };
  }

  /// Index of the current stage; `PipelineStage.ordered.length` when done,
  /// -1 when nothing has started.
  static int _stageIndexOf(Job? job) {
    if (job == null) return -1;
    if (job.status == JobStatus.completed) return PipelineStage.ordered.length;
    final i = PipelineStage.ordered
        .indexWhere((s) => s.label == job.currentStage);
    return i;
  }

  static _StageState _stageState(
    PipelineStage stage, {
    required int index,
    required int currentIndex,
    required PipelineRunState runState,
  }) {
    if (index < currentIndex) return _StageState.done;
    if (index > currentIndex) return _StageState.pending;
    // Current index:
    return switch (runState) {
      PipelineRunState.completed => _StageState.done,
      PipelineRunState.failed => _StageState.error,
      PipelineRunState.cancelled => _StageState.error,
      _ => _StageState.active,
    };
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.runState, required this.job});

  final PipelineRunState runState;
  final Job? job;

  @override
  Widget build(BuildContext context) {
    final j = job;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.sm + 2,
            vertical: 3,
          ),
          decoration: BoxDecoration(
            color: runState.color.withValues(alpha: 0.10),
            borderRadius: AppRadius.rSm,
          ),
          child: Text(
            runState.label,
            style: AppTypography.label.copyWith(color: runState.color),
          ),
        ),
        if (j != null) ...[
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Text(
              '${j.type.name} · ${j.currentStage}',
              style: AppTypography.secondary
                  .copyWith(color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${(j.progress * 100).round()}%',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontSize: AppTypography.sizeSm,
            ),
          ),
        ] else
          const Spacer(),
      ],
    );
  }
}

enum _StageState { pending, active, done, error }

class _StageRow extends StatelessWidget {
  const _StageRow({required this.stage, required this.state});

  final PipelineStage stage;
  final _StageState state;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _StageState.pending => AppColors.textTertiary,
      _StageState.active => AppColors.accent,
      _StageState.done => AppColors.success,
      _StageState.error => AppColors.danger,
    };

    return SizedBox(
      height: 26,
      child: Row(
        children: [
          if (state == _StageState.done)
            Icon(Icons.check, size: 14, color: color)
          else
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: state == _StageState.pending
                    ? AppColors.border
                    : color,
              ),
            ),
          const SizedBox(width: Spacing.md),
          Text(
            stage.label,
            style: AppTypography.secondary.copyWith(
              color: state == _StageState.pending
                  ? AppColors.textTertiary
                  : AppColors.textPrimary,
              fontWeight: state == _StageState.active
                  ? AppTypography.wMedium
                  : AppTypography.wRegular,
            ),
          ),
        ],
      ),
    );
  }
}
