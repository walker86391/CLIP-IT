import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/providers/core_providers.dart';
import '../../youtube/providers/youtube_download_provider.dart';
import '../../youtube/services/youtube_download_service.dart';

/// Real item representing a downloaded video on disk.
class DownloadedVideoItem {
  const DownloadedVideoItem({
    required this.fileName,
    required this.filePath,
    required this.fileSizeBytes,
    required this.modifiedTime,
    required this.format,
  });

  final String fileName;
  final String filePath;
  final int fileSizeBytes;
  final DateTime modifiedTime;
  final String format;

  String get formattedSize {
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    } else if (fileSizeBytes < 1024 * 1024 * 1024) {
      return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  String get formattedDate {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final m = months[modifiedTime.month - 1];
    final d = modifiedTime.day.toString().padLeft(2, '0');
    final y = modifiedTime.year;
    final h = modifiedTime.hour.toString().padLeft(2, '0');
    final min = modifiedTime.minute.toString().padLeft(2, '0');
    return '$m $d, $y - $h:$min';
  }
}

/// Downloads & Export History Screen for ClipIt.
///
/// Automatically tracks the active download folder configured in Downloader,
/// refreshes whenever opened or navigated to, provides a manual Refresh button on top,
/// and lists all real downloaded video files with play and reveal actions.
class DownloadsPage extends ConsumerStatefulWidget {
  const DownloadsPage({super.key});

  @override
  ConsumerState<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends ConsumerState<DownloadsPage> {
  List<DownloadedVideoItem> _videos = [];
  bool _isLoading = true;
  String _currentDirectory = '';

  static const _supportedVideoExts = {
    '.mp4',
    '.webm',
    '.mkv',
    '.mov',
    '.avi',
    '.flv',
    '.m4v',
    '.ts',
    '.wmv',
  };

  @override
  void initState() {
    super.initState();
    _refreshFiles();
  }

  Future<void> _refreshFiles() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    // Follow the download directory from YoutubeDownloadService / provider
    String dirPath = ref.read(youtubeDownloadProvider).downloadDirectory;
    if (dirPath.isEmpty) {
      dirPath = await YoutubeDownloadService.instance.getDownloadDirectory();
    }

    final items = <DownloadedVideoItem>[];
    final dir = Directory(dirPath);

    if (dir.existsSync()) {
      try {
        final entries = dir.listSync(followLinks: false);
        for (final entry in entries) {
          if (entry is File) {
            final ext = p.extension(entry.path).toLowerCase();
            // Skip partial/temporary downloads
            if (_supportedVideoExts.contains(ext) &&
                !entry.path.endsWith('.part') &&
                !entry.path.endsWith('.ytdl')) {
              try {
                final stat = entry.statSync();
                items.add(DownloadedVideoItem(
                  fileName: p.basename(entry.path),
                  filePath: entry.path,
                  fileSizeBytes: stat.size,
                  modifiedTime: stat.modified,
                  format: ext.replaceAll('.', '').toUpperCase(),
                ));
              } catch (_) {}
            }
          }
        }
        // Most recent downloads first
        items.sort((a, b) => b.modifiedTime.compareTo(a.modifiedTime));
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _currentDirectory = dirPath;
        _videos = items;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Automatically re-scan whenever user navigates to the Downloads tab (index 4)
    ref.listen(shellNavigationIndexProvider, (prev, next) {
      if (next == 4) {
        _refreshFiles();
      }
    });

    // Automatically follow if the download folder changes elsewhere
    ref.listen<String>(
      youtubeDownloadProvider.select((s) => s.downloadDirectory),
      (prev, next) {
        if (next.isNotEmpty && next != _currentDirectory) {
          _refreshFiles();
        }
      },
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0F1016),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Row ──────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DOWNLOADS & EXPORTS',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: Color(0xFFF3F4F8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentDirectory.isNotEmpty
                            ? 'Watching folder: $_currentDirectory'
                            : 'Browse downloaded video clips and exports.',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF8E92A6),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    // Manual Refresh Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF221F33),
                        foregroundColor: const Color(0xFFC7EEF9),
                        side: const BorderSide(color: Color(0xFF383254)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isLoading ? null : _refreshFiles,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF8B5CF6),
                              ),
                            )
                          : const Icon(Icons.refresh_rounded,
                              size: 16, color: Color(0xFF8B5CF6)),
                      label: const Text(
                        'Refresh',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Open Output Folder in Explorer
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF161722),
                        foregroundColor: const Color(0xFFE2E4ED),
                        side: const BorderSide(color: Color(0xFF262838)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        final dir = _currentDirectory.isNotEmpty
                            ? _currentDirectory
                            : await YoutubeDownloadService.instance
                                .getDownloadDirectory();
                        await YoutubeDownloadService.instance.openFolder(dir);
                      },
                      icon: const Icon(
                        Icons.folder_open_rounded,
                        size: 16,
                        color: Color(0xFF8E92A6),
                      ),
                      label: const Text(
                        'Open Output Folder',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 22),

            // ── Downloads Table Container ────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF161722),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF262838),
                  width: 1.0,
                ),
              ),
              child: Column(
                children: [
                  // Table Header
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF13141E),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: Color(0xFF242636),
                          width: 1.0,
                        ),
                      ),
                    ),
                    child: Row(
                      children: const [
                        Expanded(
                          flex: 5,
                          child: Text(
                            'FILE NAME',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: Color(0xFF7E8299),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'FORMAT',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: Color(0xFF7E8299),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'SIZE',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: Color(0xFF7E8299),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'DATE MODIFIED',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: Color(0xFF7E8299),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 90,
                          child: Text(
                            'ACTIONS',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: Color(0xFF7E8299),
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Table Body
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF8B5CF6),
                        ),
                      ),
                    )
                  else if (_videos.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 48, horizontal: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E202C),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF262838),
                              ),
                            ),
                            child: const Icon(
                              Icons.movie_filter_outlined,
                              size: 26,
                              color: Color(0xFF7E8299),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'No downloaded videos found',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF3F4F8),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Videos downloaded from YouTube or Instagram will automatically appear here.\nWatching: $_currentDirectory',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7E8299),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _videos.length,
                      separatorBuilder: (_, _) => const Divider(
                        color: Color(0xFF1E202C),
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final item = _videos[index];
                        return Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              // File name + video icon
                              Expanded(
                                flex: 5,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E202C),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.movie_outlined,
                                        size: 17,
                                        color: Color(0xFF8B5CF6),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        item.fileName,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFF3F4F8),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Format badge
                              Expanded(
                                flex: 2,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF221F33),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                          color: const Color(0xFF383254)),
                                    ),
                                    child: Text(
                                      item.format,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFA78BFA),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Size
                              Expanded(
                                flex: 2,
                                child: Text(
                                  item.formattedSize,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF8E92A6),
                                  ),
                                ),
                              ),

                              // Date
                              Expanded(
                                flex: 3,
                                child: Text(
                                  item.formattedDate,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF8E92A6),
                                  ),
                                ),
                              ),

                              // Action buttons: Play and Reveal in Explorer
                              SizedBox(
                                width: 90,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                      icon: const Icon(
                                        Icons.play_circle_outline_rounded,
                                        size: 20,
                                      ),
                                      color: const Color(0xFF8B5CF6),
                                      tooltip: 'Play Video',
                                      onPressed: () =>
                                          YoutubeDownloadService.instance
                                              .openFile(item.filePath),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                      icon: const Icon(
                                        Icons.folder_outlined,
                                        size: 18,
                                      ),
                                      color: const Color(0xFF8E92A6),
                                      tooltip: 'Reveal in Explorer',
                                      onPressed: () =>
                                          YoutubeDownloadService.instance
                                              .revealFile(item.filePath),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
