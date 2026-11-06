import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/providers/core_providers.dart';
import '../../../core/utils/app_path_resolver.dart';
import '../../pipeline/models/pipeline_job.dart';
import '../../pipeline/providers/pipeline_provider.dart';

/// Professional Media Library Clips Screen for ClipIt.
class ClipsPage extends ConsumerStatefulWidget {
  const ClipsPage({super.key});

  @override
  ConsumerState<ClipsPage> createState() => _ClipsPageState();
}

class _ClipsPageState extends ConsumerState<ClipsPage> {
  String _selectedRatio = 'All Ratios';

  @override
  Widget build(BuildContext context) {
    // Collect live and completed pipeline clips
    final activeJob = ref.watch(pipelineJobProvider);
    final history = ref.watch(pipelineHistoryProvider);

    final realClips = <Map<String, dynamic>>[];
    final allJobs = [?activeJob, ...history.where((j) => j.id != activeJob?.id)];

    for (final job in allJobs) {
      final clipsDir = job.clipsDir ?? AppPathResolver.getLiveProcessClipsDir(p.basename(job.projectDir ?? 'project 2')).path;
      for (final clip in job.clips.where((c) => c.isPermanent)) {
        final wbwPath = p.join(clipsDir, '${clip.id}_word_by_word.mp4');
        final normalPath = p.join(clipsDir, '${clip.id}_normal.mp4');
        final hasWbw = File(wbwPath).existsSync();
        final hasNormal = File(normalPath).existsSync();
        final renderedPath = hasWbw
            ? wbwPath
            : (hasNormal ? normalPath : (clip.outputPath != null && File(clip.outputPath!).existsSync() ? clip.outputPath : null));

        realClips.add({
          'title': clip.hookTitle,
          'duration': '${clip.durationSec.round()}s',
          'aspect': '9:16',
          'viralScore': '${clip.viralScore.round()} Viral',
          'source': job.videoTitle,
          'views': renderedPath != null ? 'Rendered' : 'Confirmed',
          'date': 'Generated just now',
          'isReal': true,
          'outputPath': renderedPath,
          'wordByWordPath': hasWbw ? wbwPath : null,
          'normalPath': hasNormal ? normalPath : null,
          'clipsDir': clipsDir,
          'clip': clip,
          'job': job,
        });
      }
    }

    final searchQuery = ref.watch(globalSearchQueryProvider).trim().toLowerCase();

    final filtered = realClips.where((c) {
      if (searchQuery.isNotEmpty) {
        final title = (c['title'] as String? ?? '').toLowerCase();
        final source = (c['source'] as String? ?? '').toLowerCase();
        if (!title.contains(searchQuery) && !source.contains(searchQuery)) {
          return false;
        }
      }
      if (_selectedRatio == 'All Ratios') return true;
      if (_selectedRatio == '9:16 Shorts' && c['aspect'] == '9:16') return true;
      if (_selectedRatio == '16:9 Landscape' && c['aspect'] == '16:9') {
        return true;
      }
      if (_selectedRatio == '1:1 Square' && c['aspect'] == '1:1') return true;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F1016),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CLIPS LIBRARY',
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
                            ? 'Filtering clips matching "$searchQuery"'
                            : 'Manage, review, export, and style your auto-generated clips.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8E92A6),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Import AI Clips from TXT / File
                    OutlinedButton.icon(
                      onPressed: () => _handleImportClipsText(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFC4B5FD),
                        side: const BorderSide(color: Color(0xFF3F4256)),
                        backgroundColor: const Color(0xFF161722),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.upload_file_rounded, size: 16),
                      label: const Text(
                        'Import Clips (.txt)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Batch Export / Open Output Folder
                    if (filtered.isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: () => _handleBatchExport(context, filtered),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.folder_open_rounded, size: 16),
                        label: Text(
                          'Batch Export (${filtered.length})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Filter Tabs
            Row(
              children: [
                _TabItem(
                  label: 'All Ratios (${realClips.length})',
                  isSelected: _selectedRatio == 'All Ratios',
                  onTap: () => setState(() => _selectedRatio = 'All Ratios'),
                ),
                const SizedBox(width: 8),
                _TabItem(
                  label: '9:16 Shorts',
                  isSelected: _selectedRatio == '9:16 Shorts',
                  onTap: () => setState(() => _selectedRatio = '9:16 Shorts'),
                ),
                const SizedBox(width: 8),
                _TabItem(
                  label: '16:9 Landscape',
                  isSelected: _selectedRatio == '16:9 Landscape',
                  onTap: () => setState(() => _selectedRatio = '16:9 Landscape'),
                ),
                const SizedBox(width: 8),
                _TabItem(
                  label: '1:1 Square',
                  isSelected: _selectedRatio == '1:1 Square',
                  onTap: () => setState(() => _selectedRatio = '1:1 Square'),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Clips Grid or Clean Empty State
            if (filtered.isEmpty)
              _EmptyClipsState(
                isSearchActive: searchQuery.isNotEmpty,
                onNewProject: () {
                  ref.read(shellNavigationIndexProvider.notifier).setIndex(1);
                },
                onViewOngoing: () {
                  ref.read(shellNavigationIndexProvider.notifier).setIndex(5);
                },
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 1200
                      ? 4
                      : (constraints.maxWidth > 850 ? 3 : 2);

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      mainAxisExtent: 310,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final clip = filtered[index];
                      return _ClipCard(clip: clip);
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleImportClipsText(BuildContext context) async {
    final history = ref.read(pipelineHistoryProvider);
    final activeJob = ref.read(pipelineJobProvider);
    final defaultVideo = activeJob?.videoPath.isNotEmpty == true
        ? activeJob!.videoPath
        : (history.isNotEmpty ? history.first.videoPath : '');

    final textController = TextEditingController();
    final videoController = TextEditingController(text: defaultVideo);
    bool isProcessing = false;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              backgroundColor: const Color(0xFF13141F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFF2E3146)),
              ),
              child: Container(
                width: 580,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.auto_awesome,
                                color: Color(0xFF8B5CF6),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Import AI Clips & Render Dual Subtitles',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFF3F4F8),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF8E92A6)),
                          onPressed: isProcessing ? null : () => Navigator.of(dialogCtx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Feed the ChatGPT response containing clips (JSON or text). ClipIt will align exact timestamps from transcript tokens, crop to 9:16 vertical, apply contrast boost, and render both Word-by-Word karaoke and Normal subtitles.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF8E92A6), height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: isProcessing
                              ? null
                              : () async {
                                  final files = await FilePicker.pickFiles(
                                    type: FileType.custom,
                                    allowedExtensions: ['txt', 'json'],
                                    dialogTitle: 'Select AI Clips Response (.txt or .json)',
                                  );
                                  if (files.isNotEmpty && files.first.path != null) {
                                    final file = File(files.first.path!);
                                    if (file.existsSync()) {
                                      final text = await file.readAsString();
                                      setDialogState(() {
                                        textController.text = text;
                                      });
                                    }
                                  }
                                },
                          icon: const Icon(Icons.file_open_outlined, size: 15),
                          label: const Text('Browse .txt / .json File'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFC4B5FD),
                            side: const BorderSide(color: Color(0xFF3F4256)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'or paste response text below:',
                            style: TextStyle(fontSize: 11.5, color: Color(0xFF7E8299)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: textController,
                      maxLines: 7,
                      enabled: !isProcessing,
                      style: const TextStyle(fontSize: 12, fontFamily: 'Consolas', color: Color(0xFFE2E4ED)),
                      decoration: InputDecoration(
                        hintText: 'Paste ChatGPT JSON or text containing clips here...',
                        hintStyle: const TextStyle(fontSize: 11.5, color: Color(0xFF4B4E62)),
                        filled: true,
                        fillColor: const Color(0xFF0F1016),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF2A2D3E)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF2A2D3E)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: videoController,
                            enabled: !isProcessing,
                            style: const TextStyle(fontSize: 12, color: Color(0xFFE2E4ED)),
                            decoration: InputDecoration(
                              labelText: 'Source Video Path (MP4)',
                              labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF8E92A6)),
                              hintText: 'C:\\path\\to\\source_video.mp4',
                              hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF4B4E62)),
                              filled: true,
                              fillColor: const Color(0xFF0F1016),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFF2A2D3E)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFF2A2D3E)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: isProcessing
                              ? null
                              : () async {
                                  final files = await FilePicker.pickFiles(
                                    type: FileType.video,
                                    dialogTitle: 'Select Source Video',
                                  );
                                  if (files.isNotEmpty && files.first.path != null) {
                                    setDialogState(() {
                                      videoController.text = files.first.path!;
                                    });
                                  }
                                },
                          icon: const Icon(Icons.video_library_outlined, size: 15),
                          label: const Text('Browse Video'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFC4B5FD),
                            side: const BorderSide(color: Color(0xFF3F4256)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isProcessing ? null : () => Navigator.of(dialogCtx).pop(),
                          child: const Text('Cancel', style: TextStyle(color: Color(0xFF8E92A6))),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: isProcessing
                              ? null
                              : () async {
                                  final text = textController.text.trim();
                                  if (text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please paste ChatGPT clips response or pick a file.')),
                                    );
                                    return;
                                  }
                                  setDialogState(() => isProcessing = true);
                                  try {
                                    await ref.read(pipelineJobProvider.notifier).exportClipsFromAiResponseText(
                                      text,
                                      customVideoPath: videoController.text.trim().isNotEmpty ? videoController.text.trim() : null,
                                    );
                                    if (dialogCtx.mounted) {
                                      Navigator.of(dialogCtx).pop();
                                    }
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          backgroundColor: Color(0xFF10B981),
                                          content: Text('Clips rendered successfully in dual subtitles (Word-by-Word & Normal)!'),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    setDialogState(() => isProcessing = false);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          backgroundColor: const Color(0xFFEF4444),
                                          content: Text('Export error: $e'),
                                        ),
                                      );
                                    }
                                  }
                                },
                          icon: isProcessing
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.movie_filter_rounded, size: 16),
                          label: Text(isProcessing ? 'Clipping Video...' : 'Clip & Render Subtitles'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleBatchExport(BuildContext context, List<Map<String, dynamic>> clips) async {
    if (clips.isEmpty) return;

    String? targetDir;
    for (final c in clips) {
      final cd = c['clipsDir'] as String?;
      if (cd != null && Directory(cd).existsSync()) {
        targetDir = cd;
        break;
      }
    }

    targetDir ??= AppPathResolver.getLiveProcessClipsDir('project 2').path;

    try {
      await Process.run('explorer.exe', [targetDir]);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF8B5CF6),
            content: Text('Opened clips directory in Explorer: $targetDir'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            content: Text('Could not open folder: $e'),
          ),
        );
      }
    }
  }
}

class _EmptyClipsState extends StatelessWidget {
  const _EmptyClipsState({
    required this.isSearchActive,
    required this.onNewProject,
    required this.onViewOngoing,
  });

  final bool isSearchActive;
  final VoidCallback onNewProject;
  final VoidCallback onViewOngoing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF13141E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222432)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF1F2233),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF2E3248)),
            ),
            child: const Icon(
              Icons.movie_creation_outlined,
              size: 32,
              color: Color(0xFF8B5CF6),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            isSearchActive
                ? 'No matching clips found'
                : 'No clips generated yet',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFFF3F4F8),
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(
              isSearchActive
                  ? 'Try searching with a different keyword or clear the search bar on top.'
                  : 'Start a new project or import a YouTube video to transcribe, auto-discover viral hooks, and render edited clips.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF8E92A6),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: onNewProject,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Start New Project'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: onViewOngoing,
                icon: const Icon(Icons.bolt_rounded, size: 16),
                label: const Text('Ongoing Process'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE2E4ED),
                  side: const BorderSide(color: Color(0xFF2E3146)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClipCard extends ConsumerStatefulWidget {
  const _ClipCard({required this.clip});

  final Map<String, dynamic> clip;

  @override
  ConsumerState<_ClipCard> createState() => _ClipCardState();
}

class _ClipCardState extends ConsumerState<_ClipCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.clip;
    final outputPath = c['outputPath'] as String?;
    final wordByWordPath = c['wordByWordPath'] as String?;
    final normalPath = c['normalPath'] as String?;
    final clipsDir = c['clipsDir'] as String? ?? '';
    final hasRendered = (outputPath != null && File(outputPath).existsSync()) ||
        (wordByWordPath != null && File(wordByWordPath).existsSync()) ||
        (normalPath != null && File(normalPath).existsSync());

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () async {
          if (hasRendered) {
            final targetPath = outputPath ?? wordByWordPath ?? normalPath;
            if (targetPath != null) {
              try {
                await Process.run('explorer.exe', ['/select,', targetPath]);
              } catch (_) {}
            }
          }
        },
        child: AnimatedScale(
          scale: _hovered ? 1.012 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFF1D1F2D) : const Color(0xFF161722),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered
                  ? const Color(0xFF8B5CF6).withValues(alpha: 0.4)
                  : const Color(0xFF262838),
              width: 1.0,
            ),
            boxShadow: _hovered
                ? const [
                    BoxShadow(
                      color: Color(0x228B5CF6),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail preview
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1016),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF222432),
                      width: 0.8,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          hasRendered
                              ? Icons.play_circle_fill_rounded
                              : Icons.movie_creation_outlined,
                          size: 30,
                          color: _hovered
                              ? const Color(0xFF8B5CF6)
                              : const Color(0xFF3F4256),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                              width: 0.6,
                            ),
                          ),
                          child: Text(
                            c['viralScore'] as String,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFC4B5FD),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xCC000000),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            c['duration'] as String,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E202C),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            c['aspect'] as String,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF8E92A6),
                            ),
                          ),
                        ),
                      ),
                      if (hasRendered)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFF10B981).withValues(alpha: 0.6),
                                width: 0.6,
                              ),
                            ),
                            child: const Text(
                              'READY',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6EE7B7),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                c['title'] as String,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF3F4F8),
                  height: 1.25,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Footer metadata
              Row(
                children: [
                  Expanded(
                    child: Text(
                      c['source'] as String,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF7E8299),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    hasRendered ? 'Ready' : (c['date'] as String),
                    style: TextStyle(
                      fontSize: 10,
                      color: hasRendered ? const Color(0xFF10B981) : const Color(0xFF63667B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Subtitle Variants & Actions
              if (hasRendered)
                Row(
                  children: [
                    if (wordByWordPath != null)
                      Expanded(
                        child: Tooltip(
                          message: 'Open Word-by-Word karaoke subtitle video in Explorer',
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              try {
                                await Process.run('explorer.exe', ['/select,', wordByWordPath]);
                              } catch (_) {}
                            },
                            icon: const Icon(Icons.flash_on_rounded, size: 11, color: Color(0xFFFFB800)),
                            label: const Text(
                              'Karaoke',
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFF3F4F8),
                              side: const BorderSide(color: Color(0xFF3F4256)),
                              backgroundColor: const Color(0xFF1E202C),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              minimumSize: const Size(0, 24),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ),
                      ),
                    if (wordByWordPath != null && normalPath != null)
                      const SizedBox(width: 4),
                    if (normalPath != null)
                      Expanded(
                        child: Tooltip(
                          message: 'Open Normal dialogue subtitle video in Explorer',
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              try {
                                await Process.run('explorer.exe', ['/select,', normalPath]);
                              } catch (_) {}
                            },
                            icon: const Icon(Icons.subtitles_rounded, size: 11, color: Color(0xFF6EE7B7)),
                            label: const Text(
                              'Normal',
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFF3F4F8),
                              side: const BorderSide(color: Color(0xFF3F4256)),
                              backgroundColor: const Color(0xFF1E202C),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              minimumSize: const Size(0, 24),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 4),
                    Tooltip(
                      message: 'Open clips directory in Explorer',
                      child: IconButton(
                        icon: const Icon(Icons.folder_open_rounded, size: 14),
                        color: const Color(0xFF8B5CF6),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        onPressed: () async {
                          try {
                            await Process.run('explorer.exe', [clipsDir]);
                          } catch (_) {}
                        },
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final job = c['job'] as PipelineJob?;
                      if (job != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Rendering clips for "${job.videoTitle}"...')),
                        );
                        await ref.read(pipelineJobProvider.notifier).renderClipsForJob(job);
                      }
                    },
                    icon: const Icon(Icons.movie_creation_outlined, size: 12),
                    label: const Text(
                      'Render with Subtitles',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFC4B5FD),
                      side: const BorderSide(color: Color(0xFF8B5CF6)),
                      backgroundColor: const Color(0xFF1E1F30),
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      minimumSize: const Size(0, 24),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF221F33) : const Color(0xFF161722),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF8B5CF6)
                  : const Color(0xFF262838),
              width: 1.0,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF8E92A6),
            ),
          ),
        ),
      ),
    );
  }
}
