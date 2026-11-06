import 'package:flutter/material.dart';

import '../services/ffmpeg_service.dart';

/// Interactive diagnostic dialog displaying live verification of FFmpeg,
/// FFprobe, Windows executable paths, and supported audio/video filters.
class FfmpegDiagnosticsDialog extends StatefulWidget {
  const FfmpegDiagnosticsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const FfmpegDiagnosticsDialog(),
    );
  }

  @override
  State<FfmpegDiagnosticsDialog> createState() =>
      _FfmpegDiagnosticsDialogState();
}

class _FfmpegDiagnosticsDialogState extends State<FfmpegDiagnosticsDialog> {
  late Future<FfmpegDiagnosticReport> _reportFuture;

  @override
  void initState() {
    super.initState();
    _reportFuture =
        FfmpegService.instance.verifyInstallation(forceRefresh: true);
  }

  void _refresh() {
    setState(() {
      _reportFuture =
          FfmpegService.instance.verifyInstallation(forceRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0F111D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF26293D), width: 1.0),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: FutureBuilder<FfmpegDiagnosticReport>(
            future: _reportFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF8B5CF6)),
                      SizedBox(height: 16),
                      Text(
                        'Verifying local FFmpeg binaries & filters...',
                        style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 40, color: Color(0xFFEF4444)),
                    const SizedBox(height: 12),
                    Text(
                      'Verification Failed: ${snapshot.error}',
                      style: const TextStyle(color: Color(0xFFFCA5A5)),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refresh,
                      child: const Text('Retry Verification'),
                    ),
                  ],
                );
              }

              final r = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (r.isFullyOperational
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444))
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              r.isFullyOperational
                                  ? Icons.verified_rounded
                                  : Icons.warning_rounded,
                              size: 22,
                              color: r.isFullyOperational
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFFEF4444),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'FFmpeg Engine Diagnostics',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFF3F4F8),
                                ),
                              ),
                              Text(
                                r.isFullyOperational
                                    ? 'Installed & Operational'
                                    : 'Verification Warning',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: r.isFullyOperational
                                      ? const Color(0xFF34D399)
                                      : const Color(0xFFF87171),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            size: 20, color: Color(0xFF9CA3AF)),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(color: Color(0xFF1E2235), height: 1),
                  ),

                  // Diagnostics Content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Binary Locations
                          _buildSectionTitle('Executable Paths'),
                          const SizedBox(height: 8),
                          _buildPathRow(
                            label: 'FFmpeg Binary',
                            path: r.ffmpegPath ?? 'Not Found',
                            isFound: r.isFfmpegInstalled,
                          ),
                          const SizedBox(height: 6),
                          _buildPathRow(
                            label: 'FFprobe Binary',
                            path: r.ffprobePath ?? 'Not Found',
                            isFound: r.isFfprobeInstalled,
                          ),
                          if (r.version != null) ...[
                            const SizedBox(height: 6),
                            _buildInfoRow('Compiler Version', r.version!),
                          ],

                          const SizedBox(height: 18),

                          // Verified Filters
                          _buildSectionTitle(
                            'Required Video Filters (${r.requiredVideoFiltersFound.values.where((v) => v).length}/${r.requiredVideoFiltersFound.length})',
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: r.requiredVideoFiltersFound.entries.map((e) {
                              return _buildFilterPill(e.key, e.value);
                            }).toList(),
                          ),

                          const SizedBox(height: 18),

                          _buildSectionTitle(
                            'Required Audio Filters (${r.requiredAudioFiltersFound.values.where((v) => v).length}/${r.requiredAudioFiltersFound.length})',
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: r.requiredAudioFiltersFound.entries.map((e) {
                              return _buildFilterPill(e.key, e.value);
                            }).toList(),
                          ),

                          const SizedBox(height: 18),

                          // Summary Box
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF171A28),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF2B2F45)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline_rounded,
                                    size: 16, color: Color(0xFF9CA3AF)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    r.diagnosticSummary,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFFD1D5DB),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Re-verify Engine'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFC4B5FD),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        onPressed: _refresh,
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          textStyle: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        color: Color(0xFF9CA3AF),
      ),
    );
  }

  Widget _buildPathRow({
    required String label,
    required String path,
    required bool isFound,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF141624),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isFound
              ? const Color(0xFF10B981).withValues(alpha: 0.25)
              : const Color(0xFFEF4444).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isFound ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 14,
            color: isFound ? const Color(0xFF34D399) : const Color(0xFFEF4444),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9CA3AF),
            ),
          ),
          Expanded(
            child: Text(
              path,
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: Color(0xFFF3F4F8),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF141624),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11, color: Color(0xFFE5E7EB)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String name, bool isPresent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPresent
            ? const Color(0xFF10B981).withValues(alpha: 0.12)
            : const Color(0xFFEF4444).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isPresent
              ? const Color(0xFF10B981).withValues(alpha: 0.35)
              : const Color(0xFFEF4444).withValues(alpha: 0.35),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPresent ? Icons.check : Icons.close,
            size: 11,
            color: isPresent ? const Color(0xFF34D399) : const Color(0xFFF87171),
          ),
          const SizedBox(width: 5),
          Text(
            name,
            style: TextStyle(
              fontSize: 10.5,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
              color:
                  isPresent ? const Color(0xFFE5E7EB) : const Color(0xFFFCA5A5),
            ),
          ),
        ],
      ),
    );
  }
}
