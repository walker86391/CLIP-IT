import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/project_workflow_state.dart';

class ProjectWorkflowNotifier extends Notifier<ProjectWorkflowState> {
  @override
  ProjectWorkflowState build() {
    return const ProjectWorkflowState();
  }

  /// Starts a fresh editing session with the given uploaded video file.
  /// Resets all prior project parameters to default.
  void startNewSession({
    required String videoPath,
    required String fileName,
  }) {
    state = ProjectWorkflowState(
      hasActiveSession: true,
      videoPath: videoPath,
      videoFileName: fileName,
      videoTitle: fileName,
      currentStage: WorkflowStage.aiChatbotBridge,
      selectedDevice: PreviewDeviceType.iPhone,
      selectedRatio: VideoAspectRatio.ratio16x9,
      headTrackingEnabled: true,
      videoLanguage: 'auto',
      captionLanguage: 'hinglish',
      previewPlatformBlocks: false,
      isVideoMuted: false,
      videoVolume: 1.0,
    );
  }

  /// Transitions the user to a specific stage in the 7-stage workflow.
  void setStage(WorkflowStage stage) {
    state = state.copyWith(currentStage: stage);
  }

  /// Clears the active session and resets state back to empty.
  void resetSession() {
    state = const ProjectWorkflowState(
      hasActiveSession: false,
      currentStage: WorkflowStage.aiChatbotBridge,
    );
  }

  void selectGenre(int index, String title) {
    final prompt = GenrePromptPresets.getPromptForGenre(index);
    state = state.copyWith(
      selectedGenreIndex: index,
      genreTitle: title,
      aiPrompt: prompt,
    );
  }

  void updateAiPrompt(String newPrompt) {
    state = state.copyWith(aiPrompt: newPrompt);
  }

  void updateVideoTitle(String newTitle) {
    state = state.copyWith(videoTitle: newTitle);
  }

  void selectDevice(PreviewDeviceType device) {
    state = state.copyWith(selectedDevice: device);
  }

  void selectRatio(VideoAspectRatio ratio) {
    state = state.copyWith(selectedRatio: ratio);
  }

  void toggleHeadTracking(bool enabled) {
    state = state.copyWith(headTrackingEnabled: enabled);
  }

  void setVideoLanguage(String languageCode) {
    state = state.copyWith(videoLanguage: languageCode);
  }

  void setCaptionLanguage(String languageCode) {
    state = state.copyWith(captionLanguage: languageCode);
  }

  void togglePreviewPlatformBlocks() {
    state = state.copyWith(
      previewPlatformBlocks: !state.previewPlatformBlocks,
    );
  }

  void toggleVideoMuted() {
    final nextMuted = !state.isVideoMuted;
    state = state.copyWith(
      isVideoMuted: nextMuted,
      videoVolume: (!nextMuted && state.videoVolume <= 0.01) ? 0.8 : state.videoVolume,
    );
  }

  void setVideoMuted(bool isMuted) {
    state = state.copyWith(
      isVideoMuted: isMuted,
      videoVolume: (!isMuted && state.videoVolume <= 0.01) ? 0.8 : state.videoVolume,
    );
  }

  void setVideoVolume(double volume) {
    final clamped = volume.clamp(0.0, 1.0);
    state = state.copyWith(
      videoVolume: clamped,
      isVideoMuted: clamped <= 0.001,
    );
  }
}

final projectWorkflowProvider =
    NotifierProvider<ProjectWorkflowNotifier, ProjectWorkflowState>(
  ProjectWorkflowNotifier.new,
);
