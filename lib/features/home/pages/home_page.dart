import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../auth/providers/auth_provider.dart';
import '../../effects/providers/effects_provider.dart';
import '../../projects/providers/project_workflow_provider.dart';
import '../../sound_effects/providers/sound_effects_provider.dart';
import '../../youtube/models/youtube_download_state.dart';
import '../../youtube/providers/youtube_download_provider.dart';
import '../../youtube/widgets/youtube_download_panel.dart';
import '../models/video_upload_state.dart';
import '../providers/video_upload_provider.dart';

/// HomePage — Premium professional creative video workspace.
///
/// Features:
/// - Responsive 16:9 fullscreen optimization (no empty bottom void)
/// - Native video file selection (.mp4, .mov, .mkv)
/// - Direct YouTube video download via yt-dlp with live terminal monitor
/// - Interactive destination workflow routing
/// - Active colored NEXT button leading to second tab upload flow
/// - Matching user design: italic serif header, 2x2 grid, promo A, pricing carousel,
///   and interactive bottom drop/upload zone.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({
    this.onLongFormContentTap,
    this.onNextTap,
    super.key,
  });

  final VoidCallback? onLongFormContentTap;
  final VoidCallback? onNextTap;

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _isYoutubeMode = false;

  void _showNoUiDialog(String featureName) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF161722),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF2E3146)),
        ),
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                color: Color(0xFFF59E0B), size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                featureName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'No UI made yet for this workflow. We will make these 2 buttons next. Please choose "UPLOAD A LONG-FORM CONTENT" to proceed.',
          style: TextStyle(
            color: Color(0xFF9EA1B5),
            fontSize: 12.5,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('OK', style: TextStyle(color: Color(0xFF8B5CF6))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final uploadState = ref.watch(videoUploadProvider);
    final ytState = ref.watch(youtubeDownloadProvider);

    final rawName = authState.user?.displayName?.trim();
    final userName = (rawName != null && rawName.isNotEmpty)
        ? rawName.toUpperCase()
        : 'SHIVAM C.';

    void handlePickVideo() {
      ref.read(videoUploadProvider.notifier).pickVideoFile();
    }

    void handleNext() {
      final uploadState = ref.read(videoUploadProvider);
      final ytState = ref.read(youtubeDownloadProvider);

      String? filePath = uploadState.filePath;
      String? fileName = uploadState.fileName;

      if (_isYoutubeMode &&
          ytState.isCompleted &&
          ytState.downloadedFilePath != null) {
        filePath = ytState.downloadedFilePath;
        fileName = ytState.videoTitle ?? 'YouTube Download';
      }

      // Reset previous visual and sound effect selections
      ref.read(effectsProvider.notifier).clearAll();
      ref.read(soundEffectsProvider.notifier).clearAll();

      // Start fresh workflow session for the selected video
      ref.read(projectWorkflowProvider.notifier).startNewSession(
            videoPath: filePath ?? '',
            fileName: fileName ?? 'Video Project',
          );

      if (widget.onNextTap != null) {
        widget.onNextTap!();
      } else {
        context.go(Routes.projects);
      }
    }

    void handleLongFormTap() {
      // If an Instagram Reel is downloaded, long-form content is disabled
      if (_isYoutubeMode && ytState.isCompleted && ytState.isInstagram) {
        showDialog<void>(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            backgroundColor: const Color(0xFF161722),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFEF4444)),
            ),
            title: const Row(
              children: [
                Icon(Icons.block_rounded, color: Color(0xFFEF4444), size: 20),
                SizedBox(width: 8),
                Text(
                  'Not Available for Instagram Reels',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            content: const Text(
              'Instagram Reels are already cut short vertical clips and cannot be imported into the long-form content cutter.\n\nPlease choose "UPLOAD SHORT CLIPS ALREADY CUT" or "REUSE CLIPS" to apply styling and effects.',
              style: TextStyle(
                color: Color(0xFF9EA1B5),
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('OK', style: TextStyle(color: Color(0xFF8B5CF6))),
              ),
            ],
          ),
        );
        return;
      }

      // If a YouTube video is completed, assign it to long-form workflow
      if (_isYoutubeMode &&
          ytState.isCompleted &&
          ytState.downloadedFilePath != null) {
        if (ytState.selectedTargetWorkflow == TargetWorkflow.longForm &&
            uploadState.isReady) {
          handleNext();
          return;
        }
        ref.read(videoUploadProvider.notifier).setVideoManual(
              fileName: ytState.videoTitle ?? 'YouTube Video.mp4',
              filePath: ytState.downloadedFilePath,
              fileSizeBytes: ytState.fileSizeBytes,
            );
        ref
            .read(youtubeDownloadProvider.notifier)
            .selectTargetWorkflow(TargetWorkflow.longForm);
        ref.read(youtubeDownloadProvider.notifier).dismissTopNotification();
        return;
      }

      // If in YouTube mode without completed video, switch back to local file mode
      if (_isYoutubeMode) {
        setState(() => _isYoutubeMode = false);
      }

      if (uploadState.isReady) {
        handleNext();
      } else {
        handlePickVideo();
      }
    }

    void handleYoutubeTap() {
      setState(() => _isYoutubeMode = true);
    }

    void handleShortClipsTap() {
      if (_isYoutubeMode && ytState.isCompleted && ytState.isInstagram) {
        ref
            .read(youtubeDownloadProvider.notifier)
            .selectTargetWorkflow(TargetWorkflow.shortClips);
        ref.read(youtubeDownloadProvider.notifier).dismissTopNotification();
        showDialog<void>(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            backgroundColor: const Color(0xFF161722),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFF8B5CF6)),
            ),
            title: const Row(
              children: [
                Icon(Icons.content_cut_rounded,
                    color: Color(0xFF8B5CF6), size: 20),
                SizedBox(width: 8),
                Text(
                  'Add Effects & Styling (Short Clips)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            content: Text(
              'Instagram Reel "${ytState.videoTitle ?? 'Reel'}" selected!\n\nReels do not need cutting because they are already short clips. You can add effects, animations, and styling here.\n\nNo UI made yet for this workflow. We will make these 2 buttons next.',
              style: const TextStyle(
                color: Color(0xFF9EA1B5),
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('OK',
                    style: TextStyle(color: Color(0xFF8B5CF6))),
              ),
            ],
          ),
        );
        return;
      }
      _showNoUiDialog('UPLOAD SHORT CLIPS ALREADY CUT');
    }

    void handleReuseClipsTap() {
      if (_isYoutubeMode && ytState.isCompleted && ytState.isInstagram) {
        ref
            .read(youtubeDownloadProvider.notifier)
            .selectTargetWorkflow(TargetWorkflow.reuseClips);
        ref.read(youtubeDownloadProvider.notifier).dismissTopNotification();
        showDialog<void>(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            backgroundColor: const Color(0xFF161722),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFF8B5CF6)),
            ),
            title: const Row(
              children: [
                Icon(Icons.autorenew_rounded,
                    color: Color(0xFF8B5CF6), size: 20),
                SizedBox(width: 8),
                Text(
                  'Reuse Clips & Add Effects',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            content: Text(
              'Instagram Reel "${ytState.videoTitle ?? 'Reel'}" selected for clip reuse!\n\nReels do not need cutting. You can repurpose and add new effects to this clip.\n\nNo UI made yet for this workflow. We will make these 2 buttons next.',
              style: const TextStyle(
                color: Color(0xFF9EA1B5),
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('OK',
                    style: TextStyle(color: Color(0xFF8B5CF6))),
              ),
            ],
          ),
        );
        return;
      }
      _showNoUiDialog('REUSE CLIPS');
    }

    final isLongFormDisabled =
        _isYoutubeMode && ytState.isCompleted && ytState.isInstagram;

    // Determine if NEXT can be clicked
    final isYoutubeWorkflowReady = _isYoutubeMode &&
        ytState.isCompleted &&
        !isLongFormDisabled &&
        ytState.selectedTargetWorkflow == TargetWorkflow.longForm &&
        uploadState.isReady;

    final canContinue =
        _isYoutubeMode ? isYoutubeWorkflowReady : uploadState.isReady;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1016),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 980;
          final availableHeight = constraints.maxHeight;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: availableHeight > 40 ? availableHeight - 40 : 600,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Notification Popup (shown when video is downloaded)
                    if (ytState.showTopNotification)
                      _TopNotificationBanner(
                        isInstagram: ytState.isInstagram,
                        onDismiss: () => ref
                            .read(youtubeDownloadProvider.notifier)
                            .dismissTopNotification(),
                      ),

                    // Top Section: Welcome + Action Grid (Left) & Promo + Plans (Right)
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column: Welcome + 2x2 Action Cards (flex 6)
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _WelcomeHeader(userName: userName),
                                const SizedBox(height: 18),
                                _ActionButtonsGrid(
                                  onLongFormTap: handleLongFormTap,
                                  onYoutubeTap: handleYoutubeTap,
                                  onShortClipsTap: handleShortClipsTap,
                                  onReuseClipsTap: handleReuseClipsTap,
                                  isYoutubeActive: _isYoutubeMode,
                                  isLongFormActive: _isYoutubeMode &&
                                      !isLongFormDisabled &&
                                      ytState.selectedTargetWorkflow ==
                                          TargetWorkflow.longForm,
                                  isLongFormDisabled: isLongFormDisabled,
                                  isShortClipsActive: _isYoutubeMode &&
                                      ytState.selectedTargetWorkflow ==
                                          TargetWorkflow.shortClips,
                                  isReuseClipsActive: _isYoutubeMode &&
                                      ytState.selectedTargetWorkflow ==
                                          TargetWorkflow.reuseClips,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          // Right Column: Promo "A" Card + Subscription Panel (flex 5)
                          const Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _PromoPlaceholderCard(),
                                SizedBox(height: 14),
                                _PricingPlansCard(),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _WelcomeHeader(userName: userName),
                          const SizedBox(height: 16),
                          const _PromoPlaceholderCard(),
                          const SizedBox(height: 16),
                          _ActionButtonsGrid(
                            onLongFormTap: handleLongFormTap,
                            onYoutubeTap: handleYoutubeTap,
                            onShortClipsTap: handleShortClipsTap,
                            onReuseClipsTap: handleReuseClipsTap,
                            isYoutubeActive: _isYoutubeMode,
                            isLongFormActive: _isYoutubeMode &&
                                !isLongFormDisabled &&
                                ytState.selectedTargetWorkflow ==
                                    TargetWorkflow.longForm,
                            isLongFormDisabled: isLongFormDisabled,
                            isShortClipsActive: _isYoutubeMode &&
                                ytState.selectedTargetWorkflow ==
                                    TargetWorkflow.shortClips,
                            isReuseClipsActive: _isYoutubeMode &&
                                ytState.selectedTargetWorkflow ==
                                    TargetWorkflow.reuseClips,
                          ),
                          const SizedBox(height: 16),
                          const _PricingPlansCard(),
                        ],
                      ),

                    const SizedBox(height: 18),

                    // ── Upload Status & Next Action Bar (Just above Nothing To Display / YT Panel) ──
                    _UploadStatusAndNextBar(
                      uploadState: uploadState,
                      onPickFile: handlePickVideo,
                      onNext: canContinue ? handleNext : null,
                      isYoutubeMode: _isYoutubeMode,
                      isYoutubeDownloaded: ytState.isCompleted,
                      isWorkflowSelected: ytState.selectedTargetWorkflow ==
                          TargetWorkflow.longForm,
                      onSwitchToLocal: () =>
                          setState(() => _isYoutubeMode = false),
                    ),

                    const SizedBox(height: 12),

                    // ── Bottom Area: YouTube Downloader Panel OR Nothing To Display Card ──
                    Expanded(
                      child: _isYoutubeMode
                          ? YoutubeDownloadPanel(
                              onWorkflowSelected: (wf) {
                                if (wf == TargetWorkflow.longForm) {
                                  handleLongFormTap();
                                } else if (wf == TargetWorkflow.shortClips) {
                                  handleShortClipsTap();
                                } else if (wf == TargetWorkflow.reuseClips) {
                                  handleReuseClipsTap();
                                }
                              },
                            )
                          : _EmptyStateDisplayCard(
                              uploadState: uploadState,
                              onTap: uploadState.isReady
                                   ? handleNext
                                  : handlePickVideo,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Floating Top Notification Banner when YouTube/Instagram download finishes
class _TopNotificationBanner extends StatelessWidget {
  const _TopNotificationBanner({
    required this.onDismiss,
    this.isInstagram = false,
  });

  final VoidCallback onDismiss;
  final bool isInstagram;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('youtube_top_notification_banner'),
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isInstagram
              ? const [Color(0xFF2E1528), Color(0xFF161928)]
              : const [Color(0xFF1B2A22), Color(0xFF161928)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isInstagram
                  ? const Color(0xFFE1306C)
                  : const Color(0xFF10B981))
              .withValues(alpha: 0.7),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isInstagram
                ? const Color(0x33E1306C)
                : const Color(0x3310B981),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isInstagram
                  ? const Color(0x33E1306C)
                  : const Color(0x3310B981),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_rounded,
              color: isInstagram
                  ? const Color(0xFFE1306C)
                  : const Color(0xFF10B981),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isInstagram
                      ? 'Instagram Reel downloaded successfully!'
                      : 'Video downloaded successfully!',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isInstagram
                      ? 'Reels are already cut short clips. Select "UPLOAD SHORT CLIPS ALREADY CUT" or "REUSE CLIPS" to apply effects.'
                      : 'Choose what to do next by selecting a workflow above.',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFC7EEF9),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Dismiss',
            icon: const Icon(Icons.close_rounded,
                size: 18, color: Color(0xFF8E92A6)),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

/// "WELCOME, SHIVAM C." Header
class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'WELCOME,',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontStyle: FontStyle.italic,
            fontSize: 28,
            fontWeight: FontWeight.w400,
            letterSpacing: 1.5,
            color: Color(0xFF7E7295),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          userName,
          style: const TextStyle(
            fontFamily: 'Georgia',
            fontSize: 36,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: Color(0xFFC7EEF9),
            height: 1.15,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Create, repurpose and manage your clips from one workspace.',
          style: TextStyle(
            fontSize: 12.5,
            color: Color(0xFF7E8299),
          ),
        ),
      ],
    );
  }
}

/// The Big "A" Promo Card on the top right
class _PromoPlaceholderCard extends StatelessWidget {
  const _PromoPlaceholderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF161722),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF262838), width: 1.0),
      ),
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: const Color(0xFFBCB8C6),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Text(
          'A',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 74,
            fontWeight: FontWeight.w900,
            color: Color(0xFF13111C),
          ),
        ),
      ),
    );
  }
}

/// 2x2 Action Buttons Grid with subtle framing
class _ActionButtonsGrid extends StatelessWidget {
  const _ActionButtonsGrid({
    this.onLongFormTap,
    this.onYoutubeTap,
    this.onShortClipsTap,
    this.onReuseClipsTap,
    this.isYoutubeActive = false,
    this.isLongFormActive = false,
    this.isLongFormDisabled = false,
    this.isShortClipsActive = false,
    this.isReuseClipsActive = false,
  });

  final VoidCallback? onLongFormTap;
  final VoidCallback? onYoutubeTap;
  final VoidCallback? onShortClipsTap;
  final VoidCallback? onReuseClipsTap;
  final bool isYoutubeActive;
  final bool isLongFormActive;
  final bool isLongFormDisabled;
  final bool isShortClipsActive;
  final bool isReuseClipsActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF13141E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF222432),
          width: 1.0,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  cardKey: const Key('home_action_card_long_form'),
                  icon: Icons.video_library_outlined,
                  title: 'UPLOAD A LONG-\nFORM CONTENT',
                  subtitle: isLongFormDisabled
                      ? 'Disabled for Instagram Reels: Reels are already short vertical clips.'
                      : 'Podcasts, lectures, interviews or livestreams.',
                  isActive: isLongFormActive,
                  isDisabled: isLongFormDisabled,
                  disabledBadge: 'DISABLED FOR REELS',
                  activeBadge: isLongFormActive ? 'READY' : null,
                  onTap: onLongFormTap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  cardKey: const Key('home_action_card_youtube'),
                  icon: Icons.play_circle_outline_rounded,
                  title: 'GET A VIDEO FROM YOUTUBE',
                  subtitle: 'Paste a link to a video you can use.',
                  isActive: isYoutubeActive,
                  activeBadge: isYoutubeActive ? 'ACTIVE' : null,
                  onTap: onYoutubeTap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  cardKey: const Key('home_action_card_short_clips'),
                  icon: Icons.content_cut_rounded,
                  title: 'UPLOAD SHORT CLIPS ALREADY CUT',
                  subtitle:
                      'Already have clips? Bring them in for captions and styling.',
                  isActive: isShortClipsActive,
                  activeBadge: isShortClipsActive ? 'SELECTED' : null,
                  onTap: onShortClipsTap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  cardKey: const Key('home_action_card_reuse_clips'),
                  icon: Icons.autorenew_rounded,
                  title: 'REUSE CLIPS',
                  subtitle: 'Continue working with previously created clips.',
                  isActive: isReuseClipsActive,
                  activeBadge: isReuseClipsActive ? 'SELECTED' : null,
                  onTap: onReuseClipsTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatefulWidget {
  const _ActionCard({
    this.cardKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isActive = false,
    this.isDisabled = false,
    this.activeBadge,
    this.disabledBadge,
    this.onTap,
  });

  final Key? cardKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isActive;
  final bool isDisabled;
  final String? activeBadge;
  final String? disabledBadge;
  final VoidCallback? onTap;

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final highlighted = !widget.isDisabled && (_hovered || widget.isActive);

    return MouseRegion(
      cursor: widget.isDisabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        key: widget.cardKey,
        onTap: widget.onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 140),
          opacity: widget.isDisabled ? 0.38 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            transform: highlighted
                ? Matrix4.translationValues(0, -2, 0)
                : Matrix4.identity(),
            height: 156,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.isDisabled
                  ? const Color(0xFF0C0D12)
                  : widget.isActive
                      ? const Color(0xFF1E1B2E)
                      : _hovered
                          ? const Color(0xFF1D1F2D)
                          : const Color(0xFF161722),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.isDisabled
                    ? const Color(0xFF1E202B)
                    : widget.isActive
                        ? const Color(0xFF8B5CF6)
                        : _hovered
                            ? const Color(0xFF8B5CF6).withValues(alpha: 0.6)
                            : const Color(0xFF262838),
                width: widget.isActive ? 1.5 : 1.0,
              ),
              boxShadow: highlighted
                  ? const [
                      BoxShadow(
                        color: Color(0x288B5CF6),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: widget.isDisabled
                            ? const Color(0xFF14151C)
                            : widget.isActive
                                ? const Color(0xFF2E244B)
                                : const Color(0xFF1E202C),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        widget.icon,
                        size: 18,
                        color: widget.isDisabled
                            ? const Color(0xFF55586D)
                            : highlighted
                                ? const Color(0xFF8B5CF6)
                                : const Color(0xFF9EA1B5),
                      ),
                    ),
                    if (widget.isDisabled && widget.disabledBadge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0x33EF4444),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: const Color(0x66EF4444),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          widget.disabledBadge!,
                          style: const TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                            color: Color(0xFFFCA5A5),
                          ),
                        ),
                      )
                    else if (widget.activeBadge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0x338B5CF6),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: const Color(0x888B5CF6),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          widget.activeBadge!,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: Color(0xFFC4B5FD),
                          ),
                        ),
                      )
                    else
                      Icon(
                        Icons.arrow_outward_rounded,
                        size: 15,
                        color: highlighted
                            ? const Color(0xFF8B5CF6)
                            : const Color(0xFF55586D),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: widget.isDisabled
                            ? const Color(0xFF6B7280)
                            : highlighted
                                ? Colors.white
                                : const Color(0xFFF3F4F8),
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: widget.isDisabled
                            ? const Color(0xFF4B5563)
                            : const Color(0xFF7E8299),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact Subscription & Plans Panel
class _PricingPlansCard extends StatefulWidget {
  const _PricingPlansCard();

  @override
  State<_PricingPlansCard> createState() => _PricingPlansCardState();
}

class _PricingPlansCardState extends State<_PricingPlansCard> {
  int _sliderIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF13141E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222432), width: 1.0),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                final inAnimation = Tween<Offset>(
                  begin: Offset(_sliderIndex == 0 ? -0.2 : 0.2, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ));
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: inAnimation,
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(_sliderIndex),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _sliderIndex == 0
                            ? const _FreePlanSubCard()
                            : const _BalancedPlanSubCard(),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _sliderIndex == 0
                            ? const _BalancedPlanSubCard()
                            : const _ProPlanSubCard(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _NavPill(
                key: const Key('pricing_slider_prev_button'),
                icon: Icons.chevron_left_rounded,
                enabled: _sliderIndex > 0,
                onTap: () {
                  if (_sliderIndex > 0) {
                    setState(() => _sliderIndex--);
                  }
                },
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  setState(() => _sliderIndex = _sliderIndex == 0 ? 1 : 0);
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    width: 90,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF222432),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeInOutCubic,
                      alignment: _sliderIndex == 0
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: Container(
                        width: 45,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _NavPill(
                key: const Key('pricing_slider_next_button'),
                icon: Icons.chevron_right_rounded,
                enabled: _sliderIndex < 1,
                onTap: () {
                  if (_sliderIndex < 1) {
                    setState(() => _sliderIndex++);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavPill extends StatelessWidget {
  const _NavPill({
    super.key,
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1B26),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: enabled ? const Color(0xFF262838) : const Color(0xFF1D1E2A),
              width: 1.0,
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: enabled ? const Color(0xFF8E92A6) : const Color(0xFF45485E),
          ),
        ),
      ),
    );
  }
}

class _FreePlanSubCard extends StatelessWidget {
  const _FreePlanSubCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161722),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF262838), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Free',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFFF3F4F8),
            ),
          ),
          const SizedBox(height: 2),
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: r'$0',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF10B981),
                  ),
                ),
                TextSpan(
                  text: ' /mo',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF7E8299),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _FeatureLine(
                text: 'UNLIMITED FREE CLIPS!',
                included: true,
                bold: true,
              ),
              _FeatureLine(text: 'Unlimited exports', included: true),
              _FeatureLine(
                text: 'SHOW ADS REGULARLY!',
                included: true,
                bold: true,
              ),
              _FeatureLine(text: 'Join the Rewards programme!', included: true),
              _FeatureLine(
                text: 'Access to all dashboard features',
                included: false,
              ),
              _FeatureLine(text: 'Auto upload clips!', included: false),
              _FeatureLine(text: 'NO ADS', included: false),
            ],
          ),
          const Spacer(),
          Container(
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF221F33),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFF383254),
                width: 0.8,
              ),
            ),
            child: const Text(
              'Current Plan',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFFC4B5FD),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalancedPlanSubCard extends StatelessWidget {
  const _BalancedPlanSubCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161928),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.45),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.tune_rounded,
                size: 15,
                color: Color(0xFF38BDF8),
              ),
              SizedBox(width: 4),
              Text(
                'Balanced',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: r'$2',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF38BDF8),
                  ),
                ),
                TextSpan(
                  text: ' /mo',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF7E8299),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _FeatureLine(
                text: 'Unlimited free clips',
                included: true,
                bold: true,
              ),
              _FeatureLine(
                text: 'Unlimited exports',
                included: true,
              ),
              _FeatureLine(
                text: 'Less ads',
                included: true,
                bold: true,
              ),
              _FeatureLine(
                text: 'Reward program',
                included: true,
              ),
              _FeatureLine(
                text: 'Some advanced features',
                included: true,
              ),
              _FeatureLine(
                text: 'Small AI integrations',
                included: true,
              ),
              _FeatureLine(
                text: 'Fully AI integrated',
                included: false,
              ),
              _FeatureLine(
                text: 'Auto-upload clips',
                included: false,
              ),
              _FeatureLine(
                text: 'Zero ads',
                included: false,
              ),
            ],
          ),
          const Spacer(),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Talk To Sales',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 3),
                  Icon(
                    Icons.arrow_outward_rounded,
                    size: 11,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProPlanSubCard extends StatelessWidget {
  const _ProPlanSubCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1B2C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.workspace_premium_rounded,
                size: 15,
                color: Color(0xFFFBBF24),
              ),
              SizedBox(width: 4),
              Text(
                'PRO+',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: r'$5',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
                TextSpan(
                  text: ' /mo',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF7E8299),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _FeatureLine(
                text: 'UNLIMITED CLIPS',
                included: true,
                bold: true,
              ),
              _FeatureLine(
                text: 'NO ADS',
                included: true,
                bold: true,
              ),
              _FeatureLine(
                text: 'ALL PRO DASHBOARD FEATURES',
                included: true,
              ),
              _FeatureLine(
                text: 'Auto Upload Clips!',
                included: true,
              ),
              _FeatureLine(
                text: 'FULL advanced AI integrations',
                included: true,
              ),
              _FeatureLine(
                text: 'Join rewards programme!',
                included: true,
              ),
            ],
          ),
          const Spacer(),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Talk To Sales',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 3),
                  Icon(
                    Icons.arrow_outward_rounded,
                    size: 11,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureLine extends StatelessWidget {
  const _FeatureLine({
    required this.text,
    required this.included,
    this.bold = false,
  });

  final String text;
  final bool included;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            included ? Icons.check_rounded : Icons.cancel_outlined,
            size: 12,
            color: included ? const Color(0xFF8B5CF6) : const Color(0xFF55586D),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                color: included ? Colors.white : const Color(0xFF6B6E82),
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ── Upload Status Bar & Next Button (placed above Nothing to Display / YT Panel) ──
class _UploadStatusAndNextBar extends StatelessWidget {
  const _UploadStatusAndNextBar({
    required this.uploadState,
    required this.onPickFile,
    required this.onNext,
    this.isYoutubeMode = false,
    this.isYoutubeDownloaded = false,
    this.isWorkflowSelected = false,
    this.onSwitchToLocal,
  });

  final VideoUploadState uploadState;
  final VoidCallback onPickFile;
  final VoidCallback? onNext;
  final bool isYoutubeMode;
  final bool isYoutubeDownloaded;
  final bool isWorkflowSelected;
  final VoidCallback? onSwitchToLocal;

  @override
  Widget build(BuildContext context) {
    final isReady = isYoutubeMode
        ? (isYoutubeDownloaded && isWorkflowSelected && uploadState.isReady)
        : uploadState.isReady;
    final isReading = !isYoutubeMode && uploadState.isReading;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF141520),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isReady
              ? const Color(0xFF8B5CF6).withValues(alpha: 0.45)
              : isReading
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.45)
                  : const Color(0xFF222432),
          width: 1.0,
        ),
        boxShadow: isReady
            ? const [
                BoxShadow(
                  color: Color(0x1F8B5CF6),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Left: Upload status / file preview
          Expanded(
            child: _buildStatusContent(context),
          ),
          const SizedBox(width: 14),

          // Right: Next Button (Colors when file is ready)
          _NextButton(
            isReady: isReady,
            onTap: onNext,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusContent(BuildContext context) {
    if (isYoutubeMode) {
      if (isYoutubeDownloaded && isWorkflowSelected && uploadState.isReady) {
        return Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 16,
              color: Color(0xFF10B981),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0x2610B981),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0x6610B981), width: 0.8),
              ),
              child: const Text(
                'READY',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: Color(0xFF10B981),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.smart_display_rounded,
              size: 16,
              color: Color(0xFFA78BFA),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                uploadState.fileName ?? 'YouTube Video',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (uploadState.formattedFileSize.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                '(${uploadState.formattedFileSize})',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF8E92A6),
                ),
              ),
            ],
            const SizedBox(width: 12),
            if (onSwitchToLocal != null)
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: onSwitchToLocal,
                  child: const Text(
                    'Switch to local file',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8B5CF6),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
          ],
        );
      }

      if (isYoutubeDownloaded) {
        return const Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: Color(0xFFFBBF24),
            ),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Video downloaded! Select "UPLOAD A LONG-FORM CONTENT" above to continue.',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFC7EEF9),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      }

      return Row(
        children: [
          const Icon(
            Icons.play_circle_fill_rounded,
            size: 16,
            color: Color(0xFFFF0033),
          ),
          const SizedBox(width: 8),
          const Flexible(
            child: Text(
              'YouTube Downloader Active — Paste a link below to download',
              style: TextStyle(
                fontSize: 11.5,
                color: Color(0xFF9EA1B5),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onSwitchToLocal != null) ...[
            const SizedBox(width: 12),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onSwitchToLocal,
                child: const Text(
                  'Upload local file instead',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8B5CF6),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    }

    if (uploadState.isReading) {
      return Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0x26F59E0B),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0x66F59E0B), width: 0.8),
            ),
            child: const Text(
              'READING',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: Color(0xFFFBBF24),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'Reading: ${uploadState.fileName ?? 'video file'}...',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFF3F4F8),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    if (uploadState.isReady) {
      return Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: Color(0xFF10B981),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0x2610B981),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0x6610B981), width: 0.8),
            ),
            child: const Text(
              'READY',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: Color(0xFF10B981),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Icon(
            Icons.video_file_outlined,
            size: 16,
            color: Color(0xFFA78BFA),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              uploadState.fileName ?? 'Video File',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (uploadState.formattedFileSize.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              '(${uploadState.formattedFileSize})',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF8E92A6),
              ),
            ),
          ],
          const SizedBox(width: 12),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onPickFile,
              child: const Text(
                'Change file',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF8B5CF6),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Idle state
    return Row(
      children: [
        const Icon(
          Icons.upload_file_outlined,
          size: 16,
          color: Color(0xFF6B6E82),
        ),
        const SizedBox(width: 8),
        const Flexible(
          child: Text(
            'No file selected — Select an MP4 or drag into the box below',
            style: TextStyle(
              fontSize: 11.5,
              color: Color(0xFF7E8299),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// The NEXT button that lights up / colors vibrant violet when ready
class _NextButton extends StatefulWidget {
  const _NextButton({
    required this.isReady,
    required this.onTap,
  });

  final bool isReady;
  final VoidCallback? onTap;

  @override
  State<_NextButton> createState() => _NextButtonState();
}

class _NextButtonState extends State<_NextButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.isReady) {
      return Container(
        key: const Key('home_upload_next_button'),
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF1B1C28),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF262838), width: 1.0),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'NEXT',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: Color(0xFF55586D),
              ),
            ),
            SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_rounded,
              size: 13,
              color: Color(0xFF55586D),
            ),
          ],
        ),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        key: const Key('home_upload_next_button'),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          transform: _hovered
              ? Matrix4.translationValues(0, -1.5, 0)
              : Matrix4.identity(),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovered ? Colors.white : const Color(0xFFA78BFA),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: _hovered
                    ? const Color(0x668B5CF6)
                    : const Color(0x448B5CF6),
                blurRadius: _hovered ? 14 : 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'NEXT',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 5),
              Icon(
                Icons.arrow_forward_rounded,
                size: 13,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The Bottom "NOTHING TO DISPLAY" Card
///
/// In 16:9 fullscreen, this card expands to fill vertical height,
/// eliminating empty space at the bottom. Tapping it opens the native file explorer.
class _EmptyStateDisplayCard extends StatefulWidget {
  const _EmptyStateDisplayCard({
    required this.uploadState,
    required this.onTap,
  });

  final VideoUploadState uploadState;
  final VoidCallback onTap;

  @override
  State<_EmptyStateDisplayCard> createState() => _EmptyStateDisplayCardState();
}

class _EmptyStateDisplayCardState extends State<_EmptyStateDisplayCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final hasFile = widget.uploadState.hasFile;
    final isReady = widget.uploadState.isReady;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        key: const Key('home_empty_state_display_card'),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          constraints: const BoxConstraints(minHeight: 120),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFF181A27) : const Color(0xFF161722),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered
                  ? const Color(0xFF8B5CF6).withValues(alpha: 0.6)
                  : const Color(0xFF262838),
              width: 1.0,
            ),
            boxShadow: _hovered
                ? const [
                    BoxShadow(
                      color: Color(0x1F8B5CF6),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: hasFile && isReady
              ? _buildReadyContent()
              : _buildEmptyContent(),
        ),
      ),
    );
  }

  Widget _buildEmptyContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'NOTHING TO DISPLAY',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
            color: Color(0xFF7E7295),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF1E202C),
            shape: BoxShape.circle,
            border: Border.all(
              color: _hovered ? const Color(0xFF8B5CF6) : const Color(0xFF2B2E42),
              width: 1.0,
            ),
          ),
          child: const Icon(
            Icons.precision_manufacturing_outlined,
            size: 22,
            color: Color(0xFF8E92A6),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _hovered
              ? 'Click to browse and upload video (.mp4, .mov, .mkv)'
              : 'Click here or "UPLOAD A LONG-FORM CONTENT" to select an MP4',
          style: TextStyle(
            fontSize: 11,
            color: _hovered ? const Color(0xFFC4B5FD) : const Color(0xFF7E8299),
          ),
        ),
      ],
    );
  }

  Widget _buildReadyContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0x2610B981),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0x6610B981), width: 0.8),
          ),
          child: const Text(
            'VIDEO READY FOR EDITING',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: Color(0xFF10B981),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF201D33),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF8B5CF6), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x268B5CF6),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.smart_display_rounded,
            size: 24,
            color: Color(0xFFA78BFA),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          widget.uploadState.fileName ?? 'Selected Video',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFFF3F4F8),
            letterSpacing: 0.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        const Text(
          'Video imported successfully. Press NEXT above to proceed or click here to choose another video.',
          style: TextStyle(
            fontSize: 11,
            color: Color(0xFF7E8299),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
