import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/chatgpt_bridge_service.dart';
import '../models/pipeline_job.dart';
import '../providers/pipeline_provider.dart';

/// Full-screen page shown when the pipeline is running.
/// Three columns: Stage stepper | Live log | Clip cards
class PipelineProgressPage extends ConsumerStatefulWidget {
  const PipelineProgressPage({
    this.onDone,
    super.key,
  });

  final VoidCallback? onDone;

  @override
  ConsumerState<PipelineProgressPage> createState() =>
      _PipelineProgressPageState();
}

class _PipelineProgressPageState extends ConsumerState<PipelineProgressPage> {
  final ScrollController _logScroll = ScrollController();

  @override
  void dispose() {
    _logScroll.dispose();
    super.dispose();
  }

  void _scrollLogToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScroll.hasClients) {
        _logScroll.animateTo(
          _logScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final job = ref.watch(pipelineJobProvider);

    if (job == null) {
      return const _EmptyState();
    }

    if (job.stage == PipelineStage.bridgeDisconnected) {
      return _BridgeDisconnectedScreen(job: job);
    }

    // Scroll log to bottom when logs change
    _scrollLogToBottom();

    return Scaffold(
      backgroundColor: const Color(0xFF0B0C14),
      body: Column(
        children: [
          _TopBar(job: job, onDone: widget.onDone),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Left: Stage Stepper ────────────────────────────────────
                SizedBox(
                  width: 240,
                  child: _StageStepper(job: job),
                ),
                const VerticalDivider(
                  width: 1,
                  color: Color(0xFF1F2233),
                ),

                // ── Centre: Live Log ───────────────────────────────────────
                Expanded(
                  flex: 5,
                  child: _LiveLogPanel(job: job, scrollController: _logScroll),
                ),

                const VerticalDivider(
                  width: 1,
                  color: Color(0xFF1F2233),
                ),

                // ── Right: Clip Cards ──────────────────────────────────────
                SizedBox(
                  width: 300,
                  child: _ClipCardsPanel(job: job),
                ),
              ],
            ),
          ),
          _ProgressBar(job: job),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top navigation bar
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.job, this.onDone});
  final PipelineJob job;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDone = job.stage == PipelineStage.completed;
    final isFailed = job.stage == PipelineStage.failed;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF0F101A),
        border: Border(
          bottom: BorderSide(color: Color(0xFF1F2233), width: 1.0),
        ),
      ),
      child: Row(
        children: [
          // Status indicator dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _stageColor(job.stage),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.videoTitle.isEmpty ? 'Untitled Video' : job.videoTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF3F4F8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  job.currentStageLabel,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF8E92A6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                width: 0.8,
              ),
            ),
            child: const Text(
              'GENERATE CLIPS PIPELINE',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: Color(0xFFC4B5FD),
              ),
            ),
          ),
          const SizedBox(width: 16),
          if (isDone)
            ElevatedButton.icon(
              onPressed: onDone,
              icon: const Icon(Icons.check_circle_rounded, size: 16),
              label: const Text('View Clips'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            )
          else if (isFailed)
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      job.errorMessage != null && job.errorMessage!.isNotEmpty
                          ? 'Error: ${job.errorMessage}'
                          : 'Pipeline failed',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    key: const Key('pipeline_progress_resume_transcription_btn'),
                    onPressed: () {
                      ref.read(pipelineJobProvider.notifier).retryOrResumeTranscription(job);
                    },
                    icon: const Icon(Icons.play_arrow_rounded, size: 16),
                    label: const Text('Resume Transcription'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _stageColor(PipelineStage stage) {
    switch (stage) {
      case PipelineStage.completed:
        return const Color(0xFF10B981);
      case PipelineStage.failed:
      case PipelineStage.cancelled:
      case PipelineStage.bridgeDisconnected:
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stage stepper (left panel)
// ─────────────────────────────────────────────────────────────────────────────

class _StageStepper extends StatelessWidget {
  const _StageStepper({required this.job});
  final PipelineJob job;

  @override
  Widget build(BuildContext context) {
    final steps = PipelineStageLabel.orderedSteps;
    final currentStageForStepper = (job.stage == PipelineStage.sendingMasterPrompt ||
            job.stage == PipelineStage.buildingMasterPrompt ||
            job.stage == PipelineStage.bridgeDisconnected)
        ? PipelineStage.discoveringClips
        : job.stage;
    final activeIdx = steps.indexOf(currentStageForStepper);

    return Container(
      color: const Color(0xFF0F101A),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PIPELINE STAGES',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: Color(0xFF6B6E82),
            ),
          ),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((entry) {
            final idx = entry.key;
            final stage = entry.value;
            final isActive = idx == activeIdx;
            final isDone = activeIdx > idx ||
                job.stage == PipelineStage.completed;
            return _StepRow(
              label: stage.label,
              isActive: isActive,
              isDone: isDone,
              isLast: idx == steps.length - 1,
              chunkInfo: stage == PipelineStage.discoveringClips &&
                      job.chunkProgress != null
                  ? 'Chunk ${job.chunkProgress}/${job.chunkTotal}'
                  : null,
            );
          }),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.label,
    required this.isActive,
    required this.isDone,
    required this.isLast,
    this.chunkInfo,
  });

  final String label;
  final bool isActive;
  final bool isDone;
  final bool isLast;
  final String? chunkInfo;

  @override
  Widget build(BuildContext context) {
    Widget icon;

    if (isDone) {
      icon = const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF10B981));
    } else if (isActive) {
      icon = const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          valueColor: AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
        ),
      );
    } else {
      icon = Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF3B3D52), width: 1.5),
        ),
      );
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? Colors.white
                          : (isDone
                              ? const Color(0xFF10B981)
                              : const Color(0xFF6B6E82)),
                    ),
                  ),
                  if (chunkInfo != null && isActive)
                    Text(
                      chunkInfo!,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (!isLast)
          Container(
            margin: const EdgeInsets.only(left: 8.5, top: 2, bottom: 2),
            width: 1,
            height: 16,
            color: isDone
                ? const Color(0xFF10B981).withValues(alpha: 0.4)
                : const Color(0xFF2A2B3D),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Live log panel (centre)
// ─────────────────────────────────────────────────────────────────────────────

class _LiveLogPanel extends StatelessWidget {
  const _LiveLogPanel({
    required this.job,
    required this.scrollController,
  });

  final PipelineJob job;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0B10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF0F101A),
              border: Border(
                bottom: BorderSide(color: Color(0xFF1F2233), width: 1.0),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.terminal_rounded,
                    size: 14, color: Color(0xFF6B6E82)),
                const SizedBox(width: 6),
                const Text(
                  'LIVE LOG',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: Color(0xFF6B6E82),
                  ),
                ),
                const Spacer(),
                Text(
                  '${job.logs.length} lines',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF4B4E62),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: job.logs.length,
              itemBuilder: (context, index) {
                final log = job.logs[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    log,
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: _logColor(log),
                      height: 1.5,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _logColor(String log) {
    if (log.contains('ERROR') || log.contains('failed') || log.contains('Warning')) {
      return const Color(0xFFEF4444);
    }
    if (log.contains('APPROVED') || log.contains('complete') || log.contains('done')) {
      return const Color(0xFF10B981);
    }
    if (log.contains('[Bridge]') || log.contains('[ChatGPT]')) {
      return const Color(0xFF8B5CF6);
    }
    if (log.contains('[FFmpeg]') || log.contains('[Render]')) {
      return const Color(0xFF3B82F6);
    }
    if (log.contains('[whisper]') || log.contains('[Transcript]')) {
      return const Color(0xFFF59E0B);
    }
    return const Color(0xFF9EA1B5);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Clip cards panel (right)
// ─────────────────────────────────────────────────────────────────────────────

class _ClipCardsPanel extends StatelessWidget {
  const _ClipCardsPanel({required this.job});
  final PipelineJob job;

  @override
  Widget build(BuildContext context) {
    final visibleClips = job.clips
        .where((c) =>
            c.status != ClipDiscoveryStatus.rejected &&
            c.status != ClipDiscoveryStatus.mightBe)
        .toList();

    return Container(
      color: const Color(0xFF0F101A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF1F2233), width: 1.0),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.movie_creation_outlined,
                    size: 14, color: Color(0xFF6B6E82)),
                const SizedBox(width: 6),
                const Text(
                  'CONFIRMED CLIPS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: Color(0xFF6B6E82),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${visibleClips.length}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: visibleClips.isEmpty
                ? const Center(
                    child: Text(
                      'Clips will appear\nhere as they\'re found',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4B4E62),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: visibleClips.length,
                    itemBuilder: (context, index) =>
                        _ClipCard(clip: visibleClips[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ClipCard extends StatelessWidget {
  const _ClipCard({required this.clip});
  final PipelineClip clip;

  @override
  Widget build(BuildContext context) {
    final isRendered = clip.outputPath != null;
    final statusColor = isRendered
        ? const Color(0xFF10B981)
        : const Color(0xFF8B5CF6);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161722),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isRendered
              ? const Color(0xFF10B981).withValues(alpha: 0.3)
              : const Color(0xFF383254),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            clip.hookTitle,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFFF3F4F8),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  isRendered ? 'RENDERED' : _statusLabel(clip.status),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  '${clip.viralScore.round()} viral',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${clip.startFormatted} → ${clip.endFormatted}  '
            '(${clip.durationSec.round()}s)',
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF7E8299),
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(ClipDiscoveryStatus status) {
    switch (status) {
      case ClipDiscoveryStatus.forSure:
        return 'FOR SURE';
      case ClipDiscoveryStatus.approved:
        return 'APPROVED';
      case ClipDiscoveryStatus.permanent:
        return 'PERMANENT';
      default:
        return status.name.toUpperCase();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom progress bar
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.job});
  final PipelineJob job;

  @override
  Widget build(BuildContext context) {
    final pct = (job.overallProgress * 100).round();
    final elapsed = job.elapsed;
    final elapsedStr = '${elapsed.inMinutes}m ${elapsed.inSeconds % 60}s';

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0C0D12),
        border: Border(
          top: BorderSide(color: Color(0xFF1B1C26), width: 1.0),
        ),
      ),
      child: Row(
        children: [
          Text(
            '$pct%',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF8B5CF6),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: job.overallProgress),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                builder: (context, animatedProgress, _) {
                  return LinearProgressIndicator(
                    value: animatedProgress,
                    minHeight: 5,
                    backgroundColor: const Color(0xFF1E202C),
                    valueColor: AlwaysStoppedAnimation(
                      job.stage == PipelineStage.completed
                          ? const Color(0xFF10B981)
                          : const Color(0xFF8B5CF6),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Elapsed: $elapsedStr',
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF6B6E82),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${job.permanentClips.length} permanent  •  '
            '${job.renderedClips.length} rendered',
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF6B6E82),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0B0C14),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF8B5CF6),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Preparing Pipeline…',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFFF3F4F8),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Initializing audio engine and AI bridge services.',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF8E92A6)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error screen shown when the ChatGPT extension bridge connection is broken
// ─────────────────────────────────────────────────────────────────────────────

class _BridgeDisconnectedScreen extends ConsumerStatefulWidget {
  const _BridgeDisconnectedScreen({required this.job});
  final PipelineJob job;

  @override
  ConsumerState<_BridgeDisconnectedScreen> createState() =>
      _BridgeDisconnectedScreenState();
}

class _BridgeDisconnectedScreenState
    extends ConsumerState<_BridgeDisconnectedScreen> {
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final bridgeState = ref.watch(chatGptBridgeProvider);
    final isConnected = bridgeState.isConnected;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0E15),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 44),
          decoration: BoxDecoration(
            color: const Color(0xFF161722),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isConnected
                  ? const Color(0xFF10B981).withValues(alpha: 0.5)
                  : const Color(0xFFEF4444).withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 36,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Glowing Icon (Red/Amber if disconnected, Green if reconnected)
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isConnected
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444))
                      .withValues(alpha: 0.12),
                  border: Border.all(
                    color: (isConnected
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444))
                        .withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: Icon(
                  isConnected
                      ? Icons.check_circle_outline_rounded
                      : Icons.sensors_off_rounded,
                  size: 38,
                  color: isConnected
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Connection Broke',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Please reopen browser or turn on extension',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF9EA1B5),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Status pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1018),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF26283B),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isConnected
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isConnected
                          ? 'Bridge Connected (${bridgeState.effectivePlatform})'
                          : (bridgeState.isConnecting
                              ? 'Waiting for browser extension...'
                              : 'Bridge Disconnected (ws://127.0.0.1:28475)'),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isConnected
                            ? const Color(0xFF10B981)
                            : const Color(0xFF9EA1B5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // Connect + Continue Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Connect button
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _errorMessage = null);
                      ref.read(chatGptBridgeProvider.notifier).startConnection();
                    },
                    icon: bridgeState.isConnecting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(
                      bridgeState.isConnecting ? 'Connecting…' : 'Connect',
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF3B3E5B)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Continue button
                  ElevatedButton.icon(
                    onPressed: () {
                      if (ref.read(chatGptBridgeProvider).isConnected) {
                        setState(() => _errorMessage = null);
                        ref
                            .read(pipelineJobProvider.notifier)
                            .resumeAfterBridgeConnected();
                      } else {
                        setState(() {
                          _errorMessage =
                              'Bridge is not connected yet. Please start the extension in ChatGPT, or click Connect.';
                        });
                      }
                    },
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    label: const Text(
                      'Continue',
                      style: TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isConnected
                          ? const Color(0xFF10B981)
                          : const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 4,
                      shadowColor: (isConnected
                              ? const Color(0xFF10B981)
                              : const Color(0xFF8B5CF6))
                          .withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  ref.read(pipelineJobProvider.notifier).cancel();
                },
                child: const Text(
                  'Cancel Pipeline',
                  style: TextStyle(
                    color: Color(0xFF6B6E82),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
