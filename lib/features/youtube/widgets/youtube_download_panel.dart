import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../models/youtube_download_state.dart';
import '../providers/youtube_download_provider.dart';
import '../services/video_source_detector.dart';

/// Interactive YouTube Downloader panel with location settings popup,
/// URL input with copyright checkbox, live yt-dlp terminal monitor,
/// and post-download video showcase.
class YoutubeDownloadPanel extends ConsumerStatefulWidget {
  const YoutubeDownloadPanel({
    super.key,
    this.onWorkflowSelected,
  });

  final void Function(TargetWorkflow workflow)? onWorkflowSelected;

  @override
  ConsumerState<YoutubeDownloadPanel> createState() =>
      _YoutubeDownloadPanelState();
}

class _YoutubeDownloadPanelState extends ConsumerState<YoutubeDownloadPanel> {
  late final TextEditingController _urlController;
  final ScrollController _terminalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _terminalScrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _terminalScrollController.hasClients) {
        _terminalScrollController.animateTo(
          _terminalScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showLocationDialog(BuildContext context, String currentPath) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161722),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF2E3146)),
          ),
          title: const Row(
            children: [
              Icon(Icons.folder_special_rounded, color: Color(0xFF8B5CF6)),
              SizedBox(width: 10),
              Text(
                'Download Location',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Videos downloaded via yt-dlp are saved here:',
                style: TextStyle(color: Color(0xFF9EA1B5), fontSize: 12),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1016),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF262838)),
                ),
                child: SelectableText(
                  currentPath.isNotEmpty ? currentPath : 'Default Downloads Folder',
                  style: const TextStyle(
                    color: Color(0xFFC7EEF9),
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFC7EEF9),
                        side: const BorderSide(color: Color(0xFF38BDF8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(dialogCtx).pop();
                        ref.read(youtubeDownloadProvider.notifier).openDownloadFolder();
                      },
                      icon: const Icon(Icons.folder_open_rounded, size: 16),
                      label: const Text('Open Folder', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.of(dialogCtx).pop();
                        await ref
                            .read(youtubeDownloadProvider.notifier)
                            .changeDownloadDirectory();
                      },
                      icon: const Icon(Icons.edit_location_alt_rounded, size: 16),
                      label: const Text('Change Location', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Close', style: TextStyle(color: Color(0xFF7E8299))),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ytState = ref.watch(youtubeDownloadProvider);
    final notifier = ref.read(youtubeDownloadProvider.notifier);

    // Auto-scroll terminal when new logs arrive
    if (ytState.isDownloading) {
      _scrollToBottom();
    }

    final displayDir = ytState.downloadDirectory.isNotEmpty
        ? ytState.downloadDirectory
        : 'Downloads/ClipIt_Downloads';

    return Container(
      constraints: const BoxConstraints(minHeight: 180),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF13141F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ytState.isCompleted
              ? const Color(0xFF10B981).withValues(alpha: 0.6)
              : ytState.isDownloading
                  ? const Color(0xFF8B5CF6).withValues(alpha: 0.6)
                  : const Color(0xFF262838),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header: "Your video will be downloaded at..." ──────────────
          _buildLocationLine(context, displayDir),

          const SizedBox(height: 14),

          // ── Content Area: Converted video card OR Input Form & Terminal ──
          if (ytState.isCompleted)
            _buildCompletedShowcase(context, ytState, notifier)
          else ...[
            _buildUrlInputRow(context, ytState, notifier),
            const SizedBox(height: 12),
            _buildCopyrightCheckbox(context, ytState, notifier),
            if (ytState.isDownloading || ytState.logs.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildTerminalMonitor(context, ytState, notifier),
            ],
          ],

          if (ytState.hasError && ytState.errorMessage != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0x22EF4444),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEF4444), width: 0.8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: Color(0xFFEF4444), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ytState.errorMessage!,
                      style: const TextStyle(
                        color: Color(0xFFFCA5A5),
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Small line above textbox: "Your video will be downloaded at: [path]"
  Widget _buildLocationLine(BuildContext context, String currentPath) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        key: const Key('youtube_download_location_line'),
        onTap: () => _showLocationDialog(context, currentPath),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF191B28),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF282B3E)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.folder_special_outlined,
                size: 15,
                color: Color(0xFFA78BFA),
              ),
              const SizedBox(width: 8),
              const Text(
                'Your video will be downloaded at: ',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF8E92A6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Expanded(
                child: Text(
                  currentPath,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFC7EEF9),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0x6638BDF8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF26283C),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Manage',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: Color(0xFFA78BFA),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.open_in_new_rounded,
                        size: 10, color: Color(0xFFA78BFA)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  /// URL input row with active / blanked-out Next / Download button
  Widget _buildUrlInputRow(
    BuildContext context,
    YoutubeDownloadState state,
    YoutubeDownloadNotifier notifier,
  ) {
    final canDownload = state.canStartDownload;
    final platformIcon = VideoSourceDetector.platformIcon(state.platform);
    final platformColor = VideoSourceDetector.platformColor(state.platform);
    final platformName =
        VideoSourceDetector.platformDisplayName(state.platform);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Textbox
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF0C0D14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: state.isDownloading
                    ? const Color(0xFF8B5CF6)
                    : state.isInstagram
                        ? const Color(0xFFE1306C)
                        : const Color(0xFF282A3C),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(
                  platformIcon,
                  color: platformColor,
                  size: 20,
                ),
                if (state.platform == VideoSourcePlatform.instagram ||
                    state.platform == VideoSourcePlatform.youtube) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: platformColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: platformColor.withValues(alpha: 0.5),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      platformName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: platformColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    key: const Key('youtube_url_input_field'),
                    controller: _urlController,
                    enabled: !state.isDownloading,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      hintText:
                          'Paste YouTube video or Instagram Reel URL (e.g. instagram.com/reel/... or youtu.be/...)',
                      hintStyle: TextStyle(
                        color: Color(0xFF55586D),
                        fontSize: 12,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: (val) => notifier.setVideoUrl(val),
                  ),
                ),
                if (_urlController.text.isNotEmpty && !state.isDownloading)
                  IconButton(
                    icon: const Icon(Icons.clear_rounded,
                        size: 16, color: Color(0xFF6B6E82)),
                    onPressed: () {
                      _urlController.clear();
                      notifier.setVideoUrl('');
                    },
                  ),
                IconButton(
                  tooltip: 'Paste from clipboard',
                  icon: const Icon(Icons.paste_rounded,
                      size: 16, color: Color(0xFF8E92A6)),
                  onPressed: state.isDownloading
                      ? null
                      : () async {
                          final data = await Clipboard.getData('text/plain');
                          if (data?.text != null && data!.text!.isNotEmpty) {
                            _urlController.text = data.text!;
                            notifier.setVideoUrl(data.text!);
                          }
                        },
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Action / Next Button
        _DownloadActionButton(
          isReady: canDownload,
          isDownloading: state.isDownloading,
          onTap: canDownload ? notifier.startDownload : null,
        ),
      ],
    );
  }

  /// Legal copyright checkbox
  Widget _buildCopyrightCheckbox(
    BuildContext context,
    YoutubeDownloadState state,
    YoutubeDownloadNotifier notifier,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 22,
          width: 22,
          child: Checkbox(
            key: const Key('youtube_legal_checkbox'),
            value: state.hasRightsConfirmed,
            onChanged: state.isDownloading
                ? null
                : (val) => notifier.setRightsConfirmed(val ?? false),
            activeColor: const Color(0xFF8B5CF6),
            checkColor: Colors.white,
            side: const BorderSide(color: Color(0xFF484B62), width: 1.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: state.isDownloading
                ? null
                : () => notifier.setRightsConfirmed(!state.hasRightsConfirmed),
            child: const Text(
              'I confirm that I own this video or have the legal right and permission to use and download it.',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF9EA1B5),
                height: 1.3,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Live Terminal / Monitor showing yt-dlp execution logs
  Widget _buildTerminalMonitor(
    BuildContext context,
    YoutubeDownloadState state,
    YoutubeDownloadNotifier notifier,
  ) {
    final pct = state.progressPercent ?? 0.0;
    final speed = state.downloadSpeed ?? '';
    final eta = state.eta ?? '';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF090A10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF222436), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Terminal Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF141520),
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
              border: Border(bottom: BorderSide(color: Color(0xFF222436))),
            ),
            child: Row(
              children: [
                // Window dots
                const Row(
                  children: [
                    CircleAvatar(radius: 4, backgroundColor: Color(0xFFEF4444)),
                    SizedBox(width: 5),
                    CircleAvatar(radius: 4, backgroundColor: Color(0xFFF59E0B)),
                    SizedBox(width: 5),
                    CircleAvatar(radius: 4, backgroundColor: Color(0xFF10B981)),
                  ],
                ),
                const SizedBox(width: 12),
                const Icon(Icons.terminal_rounded,
                    size: 13, color: Color(0xFF8B5CF6)),
                const SizedBox(width: 6),
                const Text(
                  'YT-DLP DOWNLOAD MONITOR',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: Color(0xFFC7EEF9),
                  ),
                ),
                const Spacer(),
                if (state.isDownloading) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0x2610B981),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${pct.toStringAsFixed(1)}% ${speed.isNotEmpty ? '• $speed' : ''} ${eta.isNotEmpty ? '• ETA $eta' : ''}',
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF10B981),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: notifier.cancelDownload,
                    child: const MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFFEF4444),
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Progress Bar
          if (state.isDownloading)
            LinearProgressIndicator(
              value: pct > 0 ? (pct / 100.0).clamp(0.0, 1.0) : null,
              backgroundColor: const Color(0xFF161722),
              color: const Color(0xFF8B5CF6),
              minHeight: 3,
            ),

          // Terminal Log Lines View
          Container(
            height: 140,
            padding: const EdgeInsets.all(10),
            child: ListView.builder(
              key: const Key('youtube_terminal_logs_list'),
              controller: _terminalScrollController,
              itemCount: state.logs.length,
              itemBuilder: (context, index) {
                final line = state.logs[index];
                final isSpecial = line.startsWith('[clipit]');
                final isError = line.toLowerCase().contains('error');

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1.5),
                  child: Text(
                    line,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10.5,
                      height: 1.3,
                      color: isError
                          ? const Color(0xFFEF4444)
                          : isSpecial
                              ? const Color(0xFFA78BFA)
                              : const Color(0xFF10B981),
                    ),
                  ),
                );
              },
            ),
          ),
          if (state.logs.any((l) {
            final low = l.toLowerCase();
            return low.contains('login required') ||
                low.contains('authentication required') ||
                low.contains('cookies') ||
                low.contains('rate-limit reached');
          }))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1424),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(11)),
                border: Border(top: BorderSide(color: Color(0xFF3B2349))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cookie_outlined,
                      size: 16, color: Color(0xFFF472B6)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Account login cookies required for this video. Go to Settings -> "Downloader & Cookies" to paste them.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFF9A8D4),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: () {
                      ref
                          .read(settingsCategoryIndexProvider.notifier)
                          .setIndex(2); // Downloader & Cookies tab
                      ref
                          .read(shellNavigationIndexProvider.notifier)
                          .setIndex(8); // Settings page
                    },
                    icon: const Icon(Icons.arrow_forward_rounded, size: 12),
                    label: const Text(
                      'Go to Settings',
                      style:
                          TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Converted URL box after download: video name, length, resolution, and workflows
  Widget _buildCompletedShowcase(
    BuildContext context,
    YoutubeDownloadState state,
    YoutubeDownloadNotifier notifier,
  ) {
    final title = state.videoTitle ?? 'Downloaded Video';
    final duration = state.videoDuration ?? 'HD';
    final resolution = state.videoResolution ?? '1080p';
    final size = state.formattedFileSize;

    final isInsta = state.isInstagram;
    final platformColor =
        isInsta ? const Color(0xFFE1306C) : const Color(0xFF10B981);
    final platformIcon =
        isInsta ? Icons.camera_alt_rounded : Icons.smart_display_rounded;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F111A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: platformColor.withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: platformColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: platformColor, width: 1.0),
                ),
                child: Icon(
                  platformIcon,
                  color: platformColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _BadgeChip(
                          icon: platformIcon,
                          text: isInsta ? 'INSTAGRAM REEL' : 'YOUTUBE',
                          color: platformColor,
                        ),
                        _BadgeChip(
                          icon: Icons.timer_outlined,
                          text: duration,
                          color: const Color(0xFF38BDF8),
                        ),
                        _BadgeChip(
                          icon: Icons.hd_outlined,
                          text: resolution,
                          color: const Color(0xFFA78BFA),
                        ),
                        if (size.isNotEmpty)
                          _BadgeChip(
                            icon: Icons.file_present_rounded,
                            text: size,
                            color: const Color(0xFF10B981),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Download another video',
                icon: const Icon(Icons.refresh_rounded,
                    color: Color(0xFF7E8299), size: 20),
                onPressed: notifier.reset,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF171A27),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isInsta
                    ? const Color(0xFFE1306C).withValues(alpha: 0.4)
                    : const Color(0xFF282B3E),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isInsta ? Icons.info_outline_rounded : Icons.touch_app_rounded,
                  size: 15,
                  color: isInsta
                      ? const Color(0xFFE1306C)
                      : const Color(0xFFFBBF24),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isInsta
                        ? 'Instagram Reel ready! Reels cannot be cut as long-form; select "UPLOAD SHORT CLIPS ALREADY CUT" or "REUSE CLIPS" above to apply effects.'
                        : 'Select any of the 3 buttons above to apply this video to a workflow.',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF3F4F8),
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
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadActionButton extends StatefulWidget {
  const _DownloadActionButton({
    required this.isReady,
    required this.isDownloading,
    required this.onTap,
  });

  final bool isReady;
  final bool isDownloading;
  final VoidCallback? onTap;

  @override
  State<_DownloadActionButton> createState() => _DownloadActionButtonState();
}

class _DownloadActionButtonState extends State<_DownloadActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.isReady || widget.isDownloading) {
      return Container(
        key: const Key('youtube_download_action_button'),
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1B28),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF262838), width: 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.isDownloading) ...[
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'DOWNLOADING...',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: Color(0xFF8B5CF6),
                ),
              ),
            ] else ...[
              const Text(
                'NEXT',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: Color(0xFF4C4F63),
                ),
              ),
              const SizedBox(width: 5),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 14,
                color: Color(0xFF4C4F63),
              ),
            ],
          ],
        ),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        key: const Key('youtube_download_action_button'),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          alignment: Alignment.center,
          transform: _hovered
              ? Matrix4.translationValues(0, -1.5, 0)
              : Matrix4.identity(),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered ? Colors.white : const Color(0xFFA78BFA),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: _hovered
                    ? const Color(0x668B5CF6)
                    : const Color(0x338B5CF6),
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
              SizedBox(width: 6),
              Icon(
                Icons.download_rounded,
                size: 15,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
