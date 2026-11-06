import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/effect_catalogue.dart';
import '../models/editing_effect.dart';
import '../services/vision_compositor_service.dart';

/// Notifier managing Creator-Style Effect selection, category filters, and search.
class EffectsNotifier extends Notifier<EffectsState> {
  Timer? _preparingTimer;
  bool _isDisposed = false;

  @override
  EffectsState build() {
    _isDisposed = false;
    ref.onDispose(() {
      _isDisposed = true;
      _preparingTimer?.cancel();
    });

    return const EffectsState(
      selectedEffectIds: {},
      focusedEffectId: 'CLP_FX_RAGE_SCREEN',
      activeCategory: 'ALL',
      searchQuery: '',
    );
  }

  /// Toggle selection of a creator effect via its internal ID.
  /// Continuous effects update the live video immediately.
  /// Crown Moment initiates head pose tracking if not already cached.
  Future<void> toggleEffect(
    String id, {
    String? videoFilePath,
    double timestampSeconds = 4.0,
  }) async {
    final next = Set<String>.from(state.selectedEffectIds);
    final isNowSelecting = !next.contains(id);

    if (isNowSelecting) {
      next.add(id);
    } else {
      next.remove(id);
    }

    _preparingTimer?.cancel();

    if (next.isEmpty) {
      state = state.copyWith(
        selectedEffectIds: next,
        focusedEffectId: id,
        clearProcessedFrame: true,
        clearPreparing: true,
        isProcessing: false,
      );
      return;
    }

    // Immediately update selection so continuous effects render with zero delay!
    state = state.copyWith(
      selectedEffectIds: next,
      focusedEffectId: id,
    );

    // Only Crown Moment requires computer vision head tracking
    final requiresVision = next.contains('CLP_FX_CROWN');
    final hasAnalysis = state.detectionAnalysis.isNotEmpty &&
        state.detectionAnalysis['face_detected'] != null;

    if (requiresVision && !hasAnalysis) {
      state = state.copyWith(
        isProcessing: true,
        preparingEffectName: 'Tracking head pose for Crown...',
      );

      try {
        final result = await VisionCompositorService.instance.processFrame(
          videoFilePath: videoFilePath,
          timestampSeconds: timestampSeconds,
          effectIds: {'CLP_FX_CROWN'},
        );

        if (_isDisposed) return;

        if (result != null && result.isSuccessful) {
          state = state.copyWith(
            processedFramePath: result.processedFramePath,
            detectionAnalysis: result.analysis,
            isProcessing: false,
            clearPreparing: true,
          );
        } else {
          state = state.copyWith(
            isProcessing: false,
            clearPreparing: true,
          );
        }
      } catch (_) {
        if (!_isDisposed) {
          state = state.copyWith(
            isProcessing: false,
            clearPreparing: true,
          );
        }
      }
    }
  }

  /// Explicitly triggers real computer vision processing for current selection.
  Future<void> triggerVisionProcessing({
    String? videoFilePath,
    double timestampSeconds = 4.0,
  }) async {
    if (_isDisposed) return;

    if (state.selectedEffectIds.isEmpty) {
      state = state.copyWith(
        clearProcessedFrame: true,
        isProcessing: false,
        clearPreparing: true,
      );
      return;
    }

    state = state.copyWith(
      isProcessing: true,
      preparingEffectName: 'Analyzing video frame...',
    );

    try {
      final result = await VisionCompositorService.instance.processFrame(
        videoFilePath: videoFilePath,
        timestampSeconds: timestampSeconds,
        effectIds: state.selectedEffectIds,
      );

      if (_isDisposed) return;

      if (result != null && result.isSuccessful) {
        state = state.copyWith(
          processedFramePath: result.processedFramePath,
          detectionAnalysis: result.analysis,
          isProcessing: false,
          clearPreparing: true,
        );
      } else {
        state = state.copyWith(
          isProcessing: false,
          clearPreparing: true,
        );
      }
    } catch (_) {
      if (!_isDisposed) {
        state = state.copyWith(
          isProcessing: false,
          clearPreparing: true,
        );
      }
    }
  }

  /// Select an effect explicitly.
  void selectEffect(String id, {String? videoFilePath}) {
    if (!state.selectedEffectIds.contains(id)) {
      toggleEffect(id, videoFilePath: videoFilePath);
    }
  }

  /// Deselect an effect explicitly.
  void deselectEffect(String id, {String? videoFilePath}) {
    if (state.selectedEffectIds.contains(id)) {
      toggleEffect(id, videoFilePath: videoFilePath);
    }
  }

  /// Select all visible effects in current category.
  void selectAll({String? videoFilePath}) {
    final matching = getFilteredEffects();
    final next = Set<String>.from(state.selectedEffectIds);
    for (final fx in matching) {
      next.add(fx.id);
    }
    state = state.copyWith(selectedEffectIds: next);
  }

  /// Clear all selected effects.
  void clearAll() {
    state = state.copyWith(
      selectedEffectIds: const {},
      clearProcessedFrame: true,
      isProcessing: false,
      clearPreparing: true,
    );
  }

  /// Focus an effect in the top large preview banner without altering selection.
  void setFocusedEffect(String id) {
    if (state.focusedEffectId != id) {
      state = state.copyWith(focusedEffectId: id);
    }
  }

  /// Change active category tab ('ALL', 'TRENDING', 'CHARACTER', 'AURA', etc.).
  void setActiveCategory(String category) {
    state = state.copyWith(activeCategory: category);
  }

  /// Update the search filter query.
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Returns filtered list of effects based on active category and search.
  List<EditingEffect> getFilteredEffects() {
    final query = state.searchQuery.trim().toLowerCase();
    final cat = state.activeCategory.toUpperCase();

    return EffectCatalogue.allEffects.where((effect) {
      // Category filter
      if (cat == 'TRENDING') {
        if (!effect.isTrending) return false;
      } else if (cat != 'ALL') {
        final effectCatName = effect.category.name.toUpperCase();
        if (effectCatName != cat && !cat.contains(effectCatName)) return false;
      }

      // Search query filter (matches name, description, and visual direction)
      if (query.isNotEmpty) {
        final matchesName = effect.name.toLowerCase().contains(query);
        final matchesDesc = effect.shortDescription.toLowerCase().contains(query);
        final matchesDir = effect.visualDirection.toLowerCase().contains(query);
        final matchesCat = effect.category.label.toLowerCase().contains(query);
        if (!matchesName && !matchesDesc && !matchesDir && !matchesCat) {
          return false;
        }
      }

      return true;
    }).toList();
  }
}

/// Global provider for Step 4 Effects state.
final effectsProvider =
    NotifierProvider<EffectsNotifier, EffectsState>(EffectsNotifier.new);

/// Convenience provider returning the currently focused effect.
final focusedEffectProvider = Provider<EditingEffect>((ref) {
  final focusedId = ref.watch(effectsProvider.select((s) => s.focusedEffectId));
  return EffectCatalogue.findById(focusedId) ?? EffectCatalogue.allEffects.first;
});

/// Convenience provider returning the list of filtered effects.
final filteredEffectsProvider = Provider<List<EditingEffect>>((ref) {
  final notifier = ref.watch(effectsProvider.notifier);
  // Recompute when filter/search/state changes
  ref.watch(effectsProvider.select((s) => '${s.activeCategory}|${s.searchQuery}'));
  return notifier.getFilteredEffects();
});
