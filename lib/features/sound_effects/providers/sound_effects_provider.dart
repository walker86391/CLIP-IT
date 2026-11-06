import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/sound_effects_catalogue.dart';
import '../models/sound_effect_item.dart';
import '../services/sound_effects_audio_service.dart';

/// State of the Sound Effect Library studio stage.
class SoundEffectsState {
  const SoundEffectsState({
    required this.items,
    this.selectedEffectIds = const {},
    this.searchQuery = '',
    this.selectedCategory = 'ALL',
    this.selectedFilters = const {},
    this.playingEffectId,
  });

  /// All catalogue sound effects
  final List<SoundEffectItem> items;

  /// Selected sound effect IDs to be included by the video processing engine
  final Set<String> selectedEffectIds;

  /// Search keyword filter
  final String searchQuery;

  /// Backwards-compatible category string
  final String selectedCategory;

  /// Set of multi-selected filters (e.g. {'ENGLISH', 'HINDI', 'ONLY SOUND'})
  final Set<String> selectedFilters;

  /// Currently auditioning sound effect ID, or null
  final String? playingEffectId;

  /// Number of currently selected effects
  int get selectedCount => selectedEffectIds.length;

  /// Total catalogue count
  int get totalCount => items.length;

  /// Real calculated percentage of effects selected out of total
  double get usagePercentage =>
      totalCount == 0 ? 0.0 : (selectedCount / totalCount) * 100.0;

  /// Fraction between 0.0 and 1.0 for linear progress bars
  double get usageFraction =>
      totalCount == 0 ? 0.0 : (selectedCount / totalCount).clamp(0.0, 1.0);

  /// Checks if an effect is selected
  bool isSelected(String id) => selectedEffectIds.contains(id);

  /// Checks if an effect is playing
  bool isPlaying(String id) => playingEffectId == id;

  /// Checks if a filter tag is currently active
  bool isFilterActive(String filter) {
    final upper = filter.trim().toUpperCase();
    if (upper == 'ALL') {
      return selectedFilters.isEmpty;
    }
    return selectedFilters.contains(upper);
  }

  SoundEffectsState copyWith({
    List<SoundEffectItem>? items,
    Set<String>? selectedEffectIds,
    String? searchQuery,
    String? selectedCategory,
    Set<String>? selectedFilters,
    String? Function()? playingEffectId,
  }) {
    return SoundEffectsState(
      items: items ?? this.items,
      selectedEffectIds: selectedEffectIds ?? this.selectedEffectIds,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedFilters: selectedFilters ?? this.selectedFilters,
      playingEffectId: playingEffectId != null
          ? playingEffectId()
          : this.playingEffectId,
    );
  }
}

class SoundEffectsNotifier extends Notifier<SoundEffectsState> {
  @override
  SoundEffectsState build() {
    ref.onDispose(() {
      SoundEffectsAudioService.instance.dispose();
    });

    return SoundEffectsState(
      items: SoundEffectsCatalogue.all,
      // Default with no effects auto-selected; let user choose
      selectedEffectIds: const {},
      selectedFilters: const {},
    );
  }

  /// Toggles selection of a sound effect by ID
  void toggleSelection(String id) {
    final next = Set<String>.from(state.selectedEffectIds);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    state = state.copyWith(selectedEffectIds: next);
  }

  /// Selects all available sound effects currently matching the view or catalogue
  void selectAll(List<SoundEffectItem> effects) {
    final next = Set<String>.from(state.selectedEffectIds);
    for (final effect in effects) {
      next.add(effect.id);
    }
    state = state.copyWith(selectedEffectIds: next);
  }

  /// Clears all sound effect selections
  void clearAll() {
    state = state.copyWith(selectedEffectIds: const {});
  }

  /// Updates the search keyword
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Toggles a filter tag (e.g. 'ENGLISH', 'HINDI', 'ONLY SOUND', 'MEME', etc.)
  void toggleFilter(String filter) {
    final upper = filter.trim().toUpperCase();
    if (upper == 'ALL') {
      clearFilters();
      return;
    }
    final next = Set<String>.from(state.selectedFilters);
    if (next.contains(upper)) {
      next.remove(upper);
    } else {
      next.add(upper);
    }
    state = state.copyWith(
      selectedFilters: next,
      selectedCategory: next.isEmpty ? 'ALL' : next.first,
    );
  }

  /// Clears all active filters back to ALL
  void clearFilters() {
    state = state.copyWith(
      selectedFilters: const {},
      selectedCategory: 'ALL',
    );
  }

  /// Legacy helper for category setting
  void setCategory(String category) {
    final upper = category.trim().toUpperCase();
    if (upper == 'ALL') {
      clearFilters();
    } else {
      toggleFilter(category);
    }
  }

  /// Plays or stops a sound effect
  Future<void> togglePlaySound(String id, String assetPath) async {
    await SoundEffectsAudioService.instance.playEffect(
      id: id,
      assetPath: assetPath,
      onStateChanged: (currentPlayingId) {
        state = state.copyWith(
          playingEffectId: () => currentPlayingId,
        );
      },
    );
  }

  /// Stops any actively playing audio
  Future<void> stopAudio() async {
    await SoundEffectsAudioService.instance.stop(
      onStateChanged: (currentPlayingId) {
        state = state.copyWith(
          playingEffectId: () => currentPlayingId,
        );
      },
    );
  }
}

final soundEffectsProvider =
    NotifierProvider<SoundEffectsNotifier, SoundEffectsState>(
  SoundEffectsNotifier.new,
);

/// Filtered sound effects list based on multi-select filters and search query.
final filteredSoundEffectsProvider = Provider<List<SoundEffectItem>>((ref) {
  final state = ref.watch(soundEffectsProvider);
  final query = state.searchQuery.trim().toLowerCase();
  final filters = state.selectedFilters;

  return state.items.where((effect) {
    // 1. Multi-filter match: if any filters are active, effect must match at least one
    if (filters.isNotEmpty) {
      final matches = filters.any((f) => effect.matchesFilter(f));
      if (!matches) {
        return false;
      }
    }

    // 2. Search query match (against visual name, file name, description, category, and tags)
    if (query.isNotEmpty) {
      final matchName = effect.name.toLowerCase().contains(query);
      final matchFile = effect.fileName.toLowerCase().contains(query);
      final matchDesc = effect.description.toLowerCase().contains(query);
      final matchCat = effect.category.toLowerCase().contains(query);
      final matchTags = effect.tags.any((t) => t.toLowerCase().contains(query));
      return matchName || matchFile || matchDesc || matchCat || matchTags;
    }

    return true;
  }).toList();
});
