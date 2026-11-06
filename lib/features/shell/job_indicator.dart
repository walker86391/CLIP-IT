import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/job.dart';
import '../../core/providers/core_providers.dart';
import '../../ui/tokens/colors.dart';
import '../../ui/tokens/spacing.dart';
import '../../ui/tokens/typography.dart';

/// Persistent job status pill in the shell toolbar.
///
/// Subscribes to the live job stream (JobRepo → Drift watch, fed by
/// JobServiceMock). Shows aggregate active-job state; details on hover.
/// Step 0: display only — actions live in the Processing page (TODO).
final class JobIndicator extends ConsumerWidget {
  const JobIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(recentJobsProvider);

    return jobs.when(
      loading: () => _Pill(label: 'Jobs', active: false),
      error: (_, _) => const _Pill(label: 'Jobs unavailable', active: false),
      data: (list) {
        final active = list
            .where(
              (j) =>
                  j.status == JobStatus.queued || j.status == JobStatus.running,
            )
            .toList();

        if (active.isEmpty) {
          return const _Pill(label: 'No active jobs', active: false);
        }

        final running = active
            .where((j) => j.status == JobStatus.running)
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        final avgProgress = running.isEmpty
            ? 0.0
            : running.map((j) => j.progress).reduce((a, b) => a + b) /
                running.length;

        final label = running.isEmpty
            ? '${active.length} queued'
            : '${active.length} active · ${(avgProgress * 100).round()}%';

        final tooltip = active
            .map((j) => '${j.type.name} · ${j.currentStage} · '
                '${(j.progress * 100).round()}%')
            .join('\n');

        return _Pill(label: label, active: true, tooltip: tooltip);
      },
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.active, this.tooltip});

  final String label;
  final bool active;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      height: AppSizes.controlHeightSm,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceHover,
        borderRadius: AppRadius.rMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? AppColors.accent : AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: Spacing.sm + 2),
          Text(
            label,
            style: AppTypography.secondary.copyWith(
              color: active ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: active ? AppTypography.wMedium : AppTypography.wRegular,
            ),
          ),
        ],
      ),
    );

    if (tooltip == null || tooltip!.isEmpty) return pill;
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: pill,
    );
  }
}
