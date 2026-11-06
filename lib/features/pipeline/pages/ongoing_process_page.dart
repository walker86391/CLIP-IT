import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/utils/app_path_resolver.dart';
import '../models/pipeline_job.dart';
import '../models/resumable_transcription_job.dart';
import '../providers/pipeline_provider.dart';
import 'pipeline_progress_page.dart';

/// Screen for tracking active, paused, and historical ClipIt pipeline runs.
/// Replaces all placeholder queues with real, local pipeline orchestration.
class OngoingProcessPage extends ConsumerStatefulWidget {
  const OngoingProcessPage({super.key});

  @override
  ConsumerState<OngoingProcessPage> createState() => _OngoingProcessPageState();
}

class _OngoingProcessPageState extends ConsumerState<OngoingProcessPage> {
  bool _showingDetailedView = false;

  @override
  Widget build(BuildContext context) {
    final activeJob = ref.watch(pipelineJobProvider);
    final history = ref.watch(pipelineHistoryProvider);
    final resumableJob = ref.watch(resumableTranscriptionProvider);
    final searchQuery = ref.watch(globalSearchQueryProvider).trim().toLowerCase();

    // If viewing the detailed progress of the active job
    if (_showingDetailedView && activeJob != null) {
      return Stack(
        children: [
          PipelineProgressPage(
            onDone: () => setState(() => _showingDetailedView = false),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF1E2032),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              onPressed: () => setState(() => _showingDetailedView = false),
              tooltip: 'Back to Processing list',
            ),
          ),
        ],
      );
    }

    // An active job must be genuinely running, paused, or cancelled (disappears when completed)
    final bool isJobShownInActiveSection = activeJob != null &&
        activeJob.stage != PipelineStage.completed &&
        activeJob.stage != PipelineStage.idle;
    final bool matchesSearch = isJobShownInActiveSection &&
        (searchQuery.isEmpty || activeJob.videoTitle.toLowerCase().contains(searchQuery));
    final currentDisplayJob = matchesSearch ? activeJob : null;

    final completedJobs = history.where((j) {
      if (searchQuery.isNotEmpty && !j.videoTitle.toLowerCase().contains(searchQuery)) {
        return false;
      }
      return !j.isActive && j.stage == PipelineStage.completed;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F1016),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ONGOING PROCESS',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: Color(0xFFF3F4F8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        searchQuery.isNotEmpty
                            ? 'Filtering by title: "$searchQuery"'
                            : 'Live pipeline orchestration: Hinglish transcription, ChatGPT discovery, and FFmpeg rendering.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8E92A6),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (currentDisplayJob != null && currentDisplayJob.isActive && !currentDisplayJob.isCancelled)
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _showingDetailedView = true),
                      icon: const Icon(Icons.fullscreen_rounded, size: 16),
                      label: const Text('Open Full Stepper'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Active Pipeline Section Header
            Row(
              children: [
                _PulsingStatusDot(
                  color: currentDisplayJob != null && currentDisplayJob.isActive
                      ? (currentDisplayJob.isPaused
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF10B981))
                      : (currentDisplayJob?.isCancelled == true
                          ? const Color(0xFFEF4444)
                          : (resumableJob != null
                              ? const Color(0xFF8B5CF6)
                              : const Color(0xFF6B6E82))),
                  isActive: (currentDisplayJob != null &&
                          currentDisplayJob.isActive &&
                          !currentDisplayJob.isPaused) ||
                      (currentDisplayJob == null && resumableJob != null),
                ),
                const SizedBox(width: 8),
                Text(
                  currentDisplayJob != null
                      ? (currentDisplayJob.isCancelled
                          ? 'CANCELLED PIPELINE'
                          : (currentDisplayJob.stage == PipelineStage.failed
                              ? 'FAILED PIPELINE'
                              : 'ACTIVE PIPELINE (1)'))
                      : (resumableJob != null
                          ? 'INTERRUPTED TRANSCRIPTION (RESUMABLE)'
                          : 'ACTIVE PIPELINE (0)'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: Color(0xFFF3F4F8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Active, Interrupted or Empty State Card
            if (currentDisplayJob != null)
              _PipelineJobCard(
                job: currentDisplayJob,
                onView: () => setState(() => _showingDetailedView = true),
                onPause: () => ref.read(pipelineJobProvider.notifier).pause(),
                onResume: () => ref.read(pipelineJobProvider.notifier).resume(),
                onResumeTranscription: () => ref
                    .read(pipelineJobProvider.notifier)
                    .retryOrResumeTranscription(currentDisplayJob),
                onCancel: () => ref.read(pipelineJobProvider.notifier).cancel(),
                onDelete: () => ref
                    .read(pipelineJobProvider.notifier)
                    .deleteJobAndFiles(currentDisplayJob),
              )
            else if (resumableJob != null)
              _InterruptedTranscriptionCard(
                resumableJob: resumableJob,
                onResume: () async {
                  await ref
                      .read(pipelineJobProvider.notifier)
                      .resumeInterruptedTranscription(resumableJob);
                  setState(() => _showingDetailedView = true);
                },
                onDiscard: () async {
                  await ref
                      .read(pipelineJobProvider.notifier)
                      .discardResumableJob(resumableJob);
                },
              )
            else
              _NoActiveJobsCard(
                searchQuery: searchQuery,
                onStartProject: () {
                  ref.read(shellNavigationIndexProvider.notifier).setIndex(0);
                },
              ),

            const SizedBox(height: 28),

            // Completed Processes Section Header
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF8B5CF6),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'COMPLETED PROCESSES (${completedJobs.length})',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: Color(0xFFF3F4F8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (completedJobs.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF161722),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF262838), width: 1.0),
                ),
                child: Center(
                  child: Text(
                    searchQuery.isNotEmpty
                        ? 'No completed processes matching "$searchQuery".'
                        : 'No completed pipeline jobs yet. Run "Generate Clips" in Step 6 to see completed exports here.',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B6E82)),
                  ),
                ),
              )
            else
              ...completedJobs.map(
                (j) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CompletedJobCard(
                    job: j,
                    onDelete: () => ref.read(pipelineJobProvider.notifier).deleteJobAndFiles(j),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Active / Paused / Cancelled Job Card
// ─────────────────────────────────────────────────────────────────────────────

class _PipelineJobCard extends StatelessWidget {
  const _PipelineJobCard({
    required this.job,
    required this.onView,
    required this.onPause,
    required this.onResume,
    this.onResumeTranscription,
    required this.onCancel,
    required this.onDelete,
  });

  final PipelineJob job;
  final VoidCallback onView;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback? onResumeTranscription;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final pct = (job.overallProgress * 100).round();
    final isCancelled = job.isCancelled;
    final isPaused = job.isPaused;

    // When cancelled: black out all buttons and the tile itself, show prominent RED DELETE button
    if (isCancelled) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF07080E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF1C1D28),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF13141C),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.cancel_outlined,
                    size: 20,
                    color: Color(0xFF6B6E82),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.videoTitle.isEmpty ? 'Untitled Video' : job.videoTitle,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B6E82),
                          decoration: TextDecoration.lineThrough,
                          decorationColor: Color(0xFFEF4444),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Pipeline cancelled by user • Work halted',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFFEF4444),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // RED DELETE BUTTON
                ElevatedButton.icon(
                  key: const Key('delete_pipeline_button'),
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_forever_rounded, size: 16),
                  label: const Text(
                    'DELETE PIPELINE & CLEANUP',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    elevation: 4,
                    shadowColor: const Color(0x66DC2626),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Clicking delete removes this pipeline from the UI and cleans up all temporary generated files. The original source video is completely safe and preserved.',
              style: TextStyle(fontSize: 11, color: Color(0xFF4C4F62)),
            ),
          ],
        ),
      );
    }

    // Normal Active / Paused Tile
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161722),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPaused ? const Color(0xFFF59E0B) : const Color(0xFF383254),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F8B5CF6),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isPaused
                            ? const Color(0xFF2C2417)
                            : (job.stage == PipelineStage.failed
                                ? const Color(0xFF2C1A1D)
                                : const Color(0xFF221F33)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isPaused
                            ? Icons.pause_rounded
                            : (job.stage == PipelineStage.failed
                                ? Icons.error_outline_rounded
                                : Icons.bolt_rounded),
                        size: 22,
                        color: isPaused
                            ? const Color(0xFFF59E0B)
                            : (job.stage == PipelineStage.failed
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF8B5CF6)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.videoTitle.isEmpty ? 'Untitled Video' : job.videoTitle,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF3F4F8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isPaused
                                ? 'PAUSED — Work suspended'
                                : (job.stage == PipelineStage.failed
                                    ? 'FAILED: ${job.errorMessage ?? "Pipeline error"}'
                                    : job.currentStageLabel),
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isPaused
                                  ? const Color(0xFFF59E0B)
                                  : (job.stage == PipelineStage.failed
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFF8B5CF6)),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Controls Row
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$pct%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isPaused
                              ? const Color(0xFFF59E0B)
                              : (job.stage == PipelineStage.failed
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF8B5CF6)),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Failed state: Resume Transcription button
                      if (job.stage == PipelineStage.failed && onResumeTranscription != null) ...[
                        ElevatedButton.icon(
                          key: const Key('resume_failed_transcription_btn'),
                          onPressed: onResumeTranscription,
                          icon: const Icon(Icons.play_arrow_rounded, size: 16),
                          label: const Text('Resume Transcription'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      // Pause Button (Enabled only when running and not paused)
                      if (!isPaused && job.stage != PipelineStage.failed) ...[
                        ElevatedButton.icon(
                          key: const Key('pause_pipeline_button'),
                          onPressed: onPause,
                          icon: const Icon(Icons.pause_rounded, size: 15),
                          label: const Text('Pause'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF221F33),
                            foregroundColor: const Color(0xFFF3F4F8),
                            side: const BorderSide(color: Color(0xFF383254)),
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      // Resume Button: enabled only when paused
                      if (job.stage != PipelineStage.failed) ...[
                        ElevatedButton.icon(
                          key: const Key('resume_pipeline_button'),
                          onPressed: isPaused ? onResume : null,
                          icon: const Icon(Icons.play_arrow_rounded, size: 15),
                          label: const Text('Resume'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isPaused
                                ? const Color(0xFF8B5CF6)
                                : const Color(0xFF1B1C27),
                            foregroundColor: isPaused
                                ? Colors.white
                                : const Color(0xFF4C4F63),
                            disabledBackgroundColor: const Color(0xFF1B1C27),
                            disabledForegroundColor: const Color(0xFF4C4F63),
                            side: BorderSide(
                              color: isPaused
                                  ? const Color(0xFF8B5CF6)
                                  : const Color(0xFF242636),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      // Cancel Button
                      ElevatedButton.icon(
                        key: const Key('cancel_pipeline_button'),
                        onPressed: onCancel,
                        icon: const Icon(Icons.cancel_outlined, size: 15),
                        label: const Text('Cancel'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25161A),
                          foregroundColor: const Color(0xFFEF4444),
                          side: const BorderSide(color: Color(0xFF422129)),
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // View Button (Detailed Stepper View)
                      ElevatedButton.icon(
                        key: const Key('view_pipeline_button'),
                        onPressed: onView,
                        icon: const Icon(Icons.visibility_outlined, size: 15),
                        label: const Text('View'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Smooth Animated Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: job.overallProgress),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              builder: (context, animatedProgress, _) {
                return LinearProgressIndicator(
                  value: animatedProgress,
                  minHeight: 6,
                  backgroundColor: const Color(0xFF1E202C),
                  valueColor: AlwaysStoppedAnimation(
                    isPaused
                        ? const Color(0xFFF59E0B)
                        : (job.stage == PipelineStage.failed
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF8B5CF6)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Elapsed: ${job.elapsed.inMinutes}m ${job.elapsed.inSeconds % 60}s',
                style: const TextStyle(fontSize: 11, color: Color(0xFF7E8299)),
              ),
              Text(
                '${job.permanentClips.length} permanent clips  •  ${job.renderedClips.length} rendered',
                style: const TextStyle(fontSize: 11, color: Color(0xFF7E8299)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State (No Active Jobs)
// ─────────────────────────────────────────────────────────────────────────────

class _NoActiveJobsCard extends StatelessWidget {
  const _NoActiveJobsCard({
    required this.searchQuery,
    required this.onStartProject,
  });

  final String searchQuery;
  final VoidCallback onStartProject;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF161722),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF262838), width: 1.0),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.hourglass_empty_rounded, size: 30, color: Color(0xFF4B4E62)),
            const SizedBox(height: 12),
            Text(
              searchQuery.isNotEmpty
                  ? 'No active processing jobs matching "$searchQuery"'
                  : 'No active video processing jobs',
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8E92A6),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Upload a video in Home or My Clips, configure Steps 1–6, then click "Generate Clips →" to begin.',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF6B6E82)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onStartProject,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Start New Project'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Completed Job Card
// ─────────────────────────────────────────────────────────────────────────────

class _CompletedJobCard extends ConsumerWidget {
  const _CompletedJobCard({
    required this.job,
    required this.onDelete,
  });

  final PipelineJob job;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSuccess = job.stage == PipelineStage.completed;
    final clipsDir = job.clipsDir ?? AppPathResolver.getLiveProcessClipsDir(job.projectId).path;
    final hasDir = Directory(clipsDir).existsSync();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF161722),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF262838), width: 1.0),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isSuccess
                  ? const Color(0xFF10B981).withValues(alpha: 0.12)
                  : const Color(0xFFEF4444).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              isSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              size: 18,
              color: isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.videoTitle.isEmpty ? 'Untitled Video' : job.videoTitle,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF3F4F8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  isSuccess
                      ? 'Completed • ${job.permanentClips.length} permanent clips • ${job.renderedClips.length} rendered'
                      : 'Failed: ${job.errorMessage ?? "Pipeline error"}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Action Buttons: Open Folder, View Clips, Re-render
          if (isSuccess && hasDir) ...[
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  await Process.run('explorer.exe', [clipsDir]);
                } catch (_) {}
              },
              icon: const Icon(Icons.folder_open_rounded, size: 14),
              label: const Text('Open Folder', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFC4B5FD),
                side: const BorderSide(color: Color(0xFF3F4256)),
                backgroundColor: const Color(0xFF1E202C),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(shellNavigationIndexProvider.notifier).setIndex(2);
              },
              icon: const Icon(Icons.movie_creation_outlined, size: 14),
              label: const Text('View Clips', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                elevation: 0,
              ),
            ),
            const SizedBox(width: 8),
          ],
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            color: const Color(0xFF6B6E82),
            hoverColor: const Color(0xFFEF4444).withValues(alpha: 0.12),
            tooltip: 'Delete completed record',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Interrupted Transcription Card (with Resume button)
// ─────────────────────────────────────────────────────────────────────────────

class _InterruptedTranscriptionCard extends StatelessWidget {
  const _InterruptedTranscriptionCard({
    required this.resumableJob,
    required this.onResume,
    required this.onDiscard,
  });

  final ResumableTranscriptionJob resumableJob;
  final VoidCallback onResume;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final pct = resumableJob.progressPercent.clamp(0.0, 100.0).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF161722),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.45),
          width: 1.4,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x248B5CF6),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                      ),
                      child: const Icon(
                        Icons.restore_page_rounded,
                        size: 24,
                        color: Color(0xFFA78BFA),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  resumableJob.videoTitle.isEmpty
                                      ? 'Untitled Project'
                                      : resumableJob.videoTitle,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFF3F4F8),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B5CF6)
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: const Color(0xFF8B5CF6)
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  '$pct% SAVED',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFA78BFA),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Interrupted Whisper transcription • ${resumableJob.wordsTranscribed} words saved up to ${resumableJob.formattedLastPosition}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9E92C6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Action Buttons: Resume & Discard
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    key: const Key('resume_interrupted_transcription_button'),
                    onPressed: onResume,
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text(
                      'Resume Transcription',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: const Color(0x6610B981),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    key: const Key('discard_interrupted_transcription_button'),
                    onPressed: onDiscard,
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: const Text(
                      'Discard',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFF422129)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (resumableJob.progressPercent / 100.0).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFF1E202C),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(
                'Position: ${resumableJob.formattedLastPosition} of ${resumableJob.formattedTotalDuration} (${resumableJob.totalChunks} audio chunk${resumableJob.totalChunks == 1 ? "" : "s"})',
                style: const TextStyle(fontSize: 11, color: Color(0xFF7E8299)),
              ),
              const Text(
                'Seamless Resume: will skip completed audio windows and continue',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Pulsing status dot for live active indicators.
class _PulsingStatusDot extends StatefulWidget {
  const _PulsingStatusDot({
    required this.color,
    required this.isActive,
  });

  final Color color;
  final bool isActive;

  @override
  State<_PulsingStatusDot> createState() => _PulsingStatusDotState();
}

class _PulsingStatusDotState extends State<_PulsingStatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _animation = Tween<double>(begin: 0.85, end: 1.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _PulsingStatusDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.value = 0.0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 8 * _animation.value,
          height: 8 * _animation.value,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.6),
                blurRadius: 6 * _animation.value,
              ),
            ],
          ),
        );
      },
    );
  }
}
