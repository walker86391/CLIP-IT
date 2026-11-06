import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/providers/video_upload_provider.dart';
import '../components/interactive_3d_device_preview.dart';
import '../components/workflow_progress_stepper.dart';
import '../models/project_workflow_state.dart';
import '../providers/project_workflow_provider.dart';

/// ProjectSettingsPage — Step 1: Project Settings.
///
/// Features:
/// - Top bar: `< Back`, `Project Settings` title, `(1) 2 3 4 5 6` stepper, `▷ Preview` button.
/// - Left column: Interactive 3D device preview with mouse drag rotation,
///   playback scrubber, controls, and "preview platform blocks" button.
/// - Vertical divider separating preview from configuration.
/// - Right column:
///   - Device selector (iPhone, Samsung, Laptop)
///   - Ratio selector pills (16:9, 1:1, 9:16, 4:5, 21:9, 3:2, Original)
///   - Head Tracking & Speaker Reframing toggle
///   - Prompts / Video Title textarea prefilled with inbuilt genre AI prompt
///   - Blue checkmark proceed button
/// - Bottom system performance status bar.
class ProjectSettingsPage extends ConsumerStatefulWidget {
  const ProjectSettingsPage({
    this.onBack,
    this.onProceed,
    this.onStepTapped,
    super.key,
  });

  final VoidCallback? onBack;
  final VoidCallback? onProceed;
  final ValueChanged<int>? onStepTapped;

  @override
  ConsumerState<ProjectSettingsPage> createState() =>
      _ProjectSettingsPageState();
}

class _ProjectSettingsPageState extends ConsumerState<ProjectSettingsPage> {
  late TextEditingController _promptTextController;
  bool _isDeviceDropdownOpen = false;
  bool _isVideoLanguageDropdownOpen = false;
  bool _isCaptionLanguageDropdownOpen = false;
  bool _isProceedHovered = false;
  bool _isProceedPressed = false;

  @override
  void initState() {
    super.initState();
    final workflowState = ref.read(projectWorkflowProvider);
    _promptTextController =
        TextEditingController(text: workflowState.aiPrompt);
  }

  @override
  void dispose() {
    _promptTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDevice = ref.watch(
      projectWorkflowProvider.select((s) => s.selectedDevice),
    );
    final selectedRatio = ref.watch(
      projectWorkflowProvider.select((s) => s.selectedRatio),
    );
    final previewPlatformBlocks = ref.watch(
      projectWorkflowProvider.select((s) => s.previewPlatformBlocks),
    );
    final headTrackingEnabled = ref.watch(
      projectWorkflowProvider.select((s) => s.headTrackingEnabled),
    );
    final videoLanguage = ref.watch(
      projectWorkflowProvider.select((s) => s.videoLanguage),
    );
    final captionLanguage = ref.watch(
      projectWorkflowProvider.select((s) => s.captionLanguage),
    );
    final isVideoMuted = ref.watch(
      projectWorkflowProvider.select((s) => s.isVideoMuted),
    );
    final uploadState = ref.watch(videoUploadProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0E15),
      body: Column(
        children: [
          // ── Top Navigation Bar ───────────────────────────────────────────
          _buildTopBar(context),

          // ── Main Content Area: Split View ────────────────────────────────
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Column: 3D Device Viewport & Media Player
                Expanded(
                  flex: 5,
                  child: Interactive3dDevicePreview(
                    deviceType: selectedDevice,
                    aspectRatio: selectedRatio,
                    previewPlatformBlocks: previewPlatformBlocks,
                    videoFilePath: uploadState.filePath,
                    isMuted: isVideoMuted,
                    onToggleMute: () {
                      ref
                          .read(projectWorkflowProvider.notifier)
                          .toggleVideoMuted();
                    },
                    onTogglePlatformBlocks: () {
                      ref
                          .read(projectWorkflowProvider.notifier)
                          .togglePreviewPlatformBlocks();
                    },
                  ),
                ),

                // Subtle Vertical Divider
                Container(
                  width: 1.0,
                  color: const Color(0xFF1E2030),
                ),

                // Right Column: Controls & Configuration
                Expanded(
                  flex: 6,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 36,
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Device Section
                        _buildSectionLabel('Device'),
                        const SizedBox(height: 8),
                        _buildDeviceDropdown(selectedDevice),

                        const SizedBox(height: 24),

                        // 2. Ratio Section
                        _buildSectionLabel('Ratio'),
                        const SizedBox(height: 8),
                        _buildRatioPills(selectedRatio),

                        const SizedBox(height: 24),

                        // 3. Head Tracking & Speaker Reframing
                        _buildHeadTrackingBox(headTrackingEnabled),

                        const SizedBox(height: 24),

                        // 4. Default Video Language
                        _buildSectionLabel('Default Video Language'),
                        const SizedBox(height: 8),
                        _buildVideoLanguageDropdown(videoLanguage),

                        const SizedBox(height: 24),

                        // 5. Expected Captions Language
                        _buildSectionLabel('Expected Captions Language'),
                        const SizedBox(height: 8),
                        _buildCaptionLanguageDropdown(captionLanguage),

                        const SizedBox(height: 28),

                        // 6. Inbuilt AI Prompt & Video Title Header & Textarea
                        const Text(
                          '-> WHAT IS THE VIDEO ABOUT / PASTE THE TITLE OF THE VIDEO IF RELEVENT!',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: Color(0xFF8B5CF6),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildPromptTextArea(),

                        const SizedBox(height: 28),

                        // Bottom right proceed checkmark button
                        Align(
                          alignment: Alignment.centerRight,
                          child: _buildProceedCheckButton(),
                        ),
                        const SizedBox(height: 20),
                      ],
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

  /// Top navigation bar matching screenshot:
  /// `< Back`   `Project Settings`   `(1) 2 3 4 5 6`   `▷ Preview`
  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF10111A),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF1D1F2D),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Back button & Title
          Row(
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: widget.onBack,
                  child: Row(
                    children: const [
                      Icon(
                        Icons.chevron_left_rounded,
                        size: 20,
                        color: Color(0xFFD1D5DB),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Back',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD1D5DB),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 36),
              const Text(
                'Project Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: Color(0xFFF3F4F8),
                ),
              ),
            ],
          ),

          // Center: Standardized 6-Step Workflow Stepper (Always fully visible across steps 1-6)
          WorkflowProgressStepper(
            currentStep: 1,
            totalSteps: 6,
            onStepTapped: widget.onStepTapped,
          ),

          // Right: Preview Pill Button
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Preview Pill Button
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161726),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.play_arrow_outlined,
                        size: 16,
                        color: Color(0xFFC4B5FD),
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Preview',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFF1F2F8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Color(0xFF8E92A6),
      ),
    );
  }

  /// Device Dropdown Card with popover options
  Widget _buildDeviceDropdown(PreviewDeviceType selectedDevice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _isDeviceDropdownOpen = !_isDeviceDropdownOpen;
              });
            },
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF141522),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF26283C),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  // Phone / Device Icon
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D1F30),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF32364C),
                        width: 1.0,
                      ),
                    ),
                    child: Icon(
                      selectedDevice == PreviewDeviceType.laptop
                          ? Icons.laptop_chromebook_rounded
                          : Icons.phone_iphone_rounded,
                      size: 20,
                      color: const Color(0xFFC4B5FD),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Device Title & Subtitle
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedDevice.displayName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFF3F4F8),
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Selected',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF7E8299),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Chevron indicator
                  Icon(
                    _isDeviceDropdownOpen
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF8E92A6),
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Popover dropdown list
        if (_isDeviceDropdownOpen) ...[
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF161726),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                width: 1.0,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: PreviewDeviceType.values.map((device) {
                final isSelected = device == selectedDevice;
                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      ref
                          .read(projectWorkflowProvider.notifier)
                          .selectDevice(device);
                      setState(() {
                        _isDeviceDropdownOpen = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF8B5CF6).withValues(alpha: 0.14)
                            : Colors.transparent,
                        border: const Border(
                          bottom: BorderSide(
                            color: Color(0xFF222436),
                            width: 0.6,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            device == PreviewDeviceType.laptop
                                ? Icons.laptop_chromebook_rounded
                                : Icons.phone_iphone_rounded,
                            size: 18,
                            color: isSelected
                                ? const Color(0xFFA78BFA)
                                : const Color(0xFF8E92A6),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  device.displayName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFFD1D5DB),
                                  ),
                                ),
                                Text(
                                  device.modelName,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Color(0xFF8B5CF6),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  /// Ratio Buttons Row: 16:9, 1:1, 9:16, 4:5, 21:9, 3:2, Original
  Widget _buildRatioPills(VideoAspectRatio selectedRatio) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: VideoAspectRatio.values.map((ratio) {
        final isSelected = ratio == selectedRatio;
        return _RatioPill(
          ratio: ratio,
          isSelected: isSelected,
          onTap: () {
            ref.read(projectWorkflowProvider.notifier).selectRatio(ratio);
          },
        );
      }).toList(),
    );
  }

  /// Head Tracking & Speaker Reframing Box with Toggle
  Widget _buildHeadTrackingBox(bool headTrackingEnabled) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141522),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF26283C),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          // Tracking Icon
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF1D1F30),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF32364C),
                width: 1.0,
              ),
            ),
            child: const Icon(
              Icons.face_retouching_natural_rounded,
              size: 20,
              color: Color(0xFFC4B5FD),
            ),
          ),
          const SizedBox(width: 14),

          // Titles
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Head Tracking & Speaker Reframing',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF3F4F8),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Adjusts framing based on head movement and keeps audio centered.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF7E8299),
                  ),
                ),
              ],
            ),
          ),

          // Toggle Switch
          Switch(
            value: headTrackingEnabled,
            onChanged: (val) {
              ref
                  .read(projectWorkflowProvider.notifier)
                  .toggleHeadTracking(val);
            },
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF8B5CF6),
            inactiveThumbColor: const Color(0xFF9CA3AF),
            inactiveTrackColor: const Color(0xFF26283C),
          ),
        ],
      ),
    );
  }

  /// Prompt / Video Title large textarea
  Widget _buildPromptTextArea() {
    return Container(
      height: 140,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF131422),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF25273D),
          width: 1.0,
        ),
      ),
      child: TextField(
        controller: _promptTextController,
        maxLines: null,
        expands: true,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFFF3F4F8),
          height: 1.4,
        ),
        onChanged: (val) {
          ref.read(projectWorkflowProvider.notifier).updateAiPrompt(val);
        },
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText:
              'Provide details about the video, context, speakers or paste a title...',
          hintStyle: TextStyle(
            fontSize: 13,
            color: Color(0xFF5A5E78),
          ),
        ),
      ),
    );
  }

  /// Proceed Blue Checkmark Button (matching GenreSelectionPage signature button)
  Widget _buildProceedCheckButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isProceedHovered = true),
      onExit: (_) => setState(() => _isProceedHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isProceedPressed = true),
        onTapUp: (_) => setState(() => _isProceedPressed = false),
        onTapCancel: () => setState(() => _isProceedPressed = false),
        onTap: () {
          if (widget.onProceed != null) {
            widget.onProceed!();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Color(0xFF1E2032),
                content: Text(
                  'Project Settings Saved • Ready for Clip Generation',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            );
          }
        },
        child: AnimatedScale(
          scale: _isProceedPressed ? 0.90 : (_isProceedHovered ? 1.08 : 1.0),
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB), // Royal blue
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isProceedHovered
                    ? Colors.white
                    : const Color(0xFF3B82F6),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isProceedHovered
                      ? const Color(0x882563EB)
                      : const Color(0x662563EB),
                  blurRadius: _isProceedHovered ? 18 : 14,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.check_rounded,
              size: 24,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  /// Default Video Language Dropdown with Auto Detect as default
  Widget _buildVideoLanguageDropdown(String currentCode) {
    final currentOption = SupportedWorkflowLanguages.videoLanguages.firstWhere(
      (l) => l.code == currentCode,
      orElse: () => SupportedWorkflowLanguages.videoLanguages.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _isVideoLanguageDropdownOpen = !_isVideoLanguageDropdownOpen;
                _isCaptionLanguageDropdownOpen = false;
                _isDeviceDropdownOpen = false;
              });
            },
            child: Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF141522),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isVideoLanguageDropdownOpen
                      ? const Color(0xFF8B5CF6)
                      : const Color(0xFF26283C),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D1F30),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF32364C),
                        width: 1.0,
                      ),
                    ),
                    child: const Icon(
                      Icons.language_rounded,
                      size: 19,
                      color: Color(0xFFC4B5FD),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentOption.label,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFF3F4F8),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Speech recognition source language',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF7E8299),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isVideoLanguageDropdownOpen
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF8E92A6),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Popover dropdown list
        if (_isVideoLanguageDropdownOpen) ...[
          const SizedBox(height: 6),
          Container(
            constraints: const BoxConstraints(maxHeight: 250),
            decoration: BoxDecoration(
              color: const Color(0xFF161726),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF2E3146),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: SupportedWorkflowLanguages.videoLanguages.length,
                separatorBuilder: (_, _) => const Divider(
                  color: Color(0xFF222436),
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final opt = SupportedWorkflowLanguages.videoLanguages[index];
                  final isSelected = opt.code == currentCode;

                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        ref
                            .read(projectWorkflowProvider.notifier)
                            .setVideoLanguage(opt.code);
                        setState(() {
                          _isVideoLanguageDropdownOpen = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 11,
                        ),
                        color: isSelected
                            ? const Color(0xFF222436)
                            : Colors.transparent,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                opt.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? const Color(0xFFC4B5FD)
                                      : const Color(0xFFD1D5E5),
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: Color(0xFF8B5CF6),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Expected Captions Language Dropdown (Hinglish default, options: Hinglish, English, Hindi)
  Widget _buildCaptionLanguageDropdown(String currentCode) {
    final currentOption = SupportedWorkflowLanguages.captionLanguages.firstWhere(
      (l) => l.code == currentCode,
      orElse: () => SupportedWorkflowLanguages.captionLanguages.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _isCaptionLanguageDropdownOpen = !_isCaptionLanguageDropdownOpen;
                _isVideoLanguageDropdownOpen = false;
                _isDeviceDropdownOpen = false;
              });
            },
            child: Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF141522),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isCaptionLanguageDropdownOpen
                      ? const Color(0xFF8B5CF6)
                      : const Color(0xFF26283C),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D1F30),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF32364C),
                        width: 1.0,
                      ),
                    ),
                    child: const Icon(
                      Icons.subtitles_rounded,
                      size: 19,
                      color: Color(0xFFC4B5FD),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentOption.label,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFF3F4F8),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Target subtitle script & format',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF7E8299),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isCaptionLanguageDropdownOpen
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF8E92A6),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Popover dropdown list (options: Hinglish, English, Hindi)
        if (_isCaptionLanguageDropdownOpen) ...[
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF161726),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF2E3146),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: SupportedWorkflowLanguages.captionLanguages.length,
                separatorBuilder: (_, _) => const Divider(
                  color: Color(0xFF222436),
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final opt = SupportedWorkflowLanguages.captionLanguages[index];
                  final isSelected = opt.code == currentCode;

                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        ref
                            .read(projectWorkflowProvider.notifier)
                            .setCaptionLanguage(opt.code);
                        setState(() {
                          _isCaptionLanguageDropdownOpen = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 11,
                        ),
                        color: isSelected
                            ? const Color(0xFF222436)
                            : Colors.transparent,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                opt.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? const Color(0xFFC4B5FD)
                                      : const Color(0xFFD1D5E5),
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: Color(0xFF8B5CF6),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _RatioPill extends StatefulWidget {
  const _RatioPill({
    required this.ratio,
    required this.isSelected,
    required this.onTap,
  });

  final VideoAspectRatio ratio;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_RatioPill> createState() => _RatioPillState();
}

class _RatioPillState extends State<_RatioPill> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final ratio = widget.ratio;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.94 : (_hovered ? 1.05 : 1.0),
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF8B5CF6).withValues(alpha: 0.18)
                  : _hovered
                      ? const Color(0xFF1B1D2C)
                      : const Color(0xFF141522),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF8B5CF6)
                    : _hovered
                        ? const Color(0xFF8B5CF6).withValues(alpha: 0.6)
                        : const Color(0xFF26283C),
                width: isSelected ? 1.4 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                        blurRadius: 10,
                      ),
                    ]
                  : _hovered
                      ? [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
            ),
            child: Text(
              ratio.label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : _hovered
                        ? const Color(0xFFF3F4F8)
                        : const Color(0xFF9CA3AF),
              ),
            ),
          ),
        ),
      ),
    );
  }

}
