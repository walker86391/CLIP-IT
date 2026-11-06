import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/subtitle_models.dart';
import '../models/subtitle_presets_library.dart';

/// State of the Stage 2 Subtitle Studio session.
class SubtitleStudioState {
  const SubtitleStudioState({
    required this.selectedPreset,
    required this.configuration,
    this.isCustomized = false,
    this.selectedCategory,
    this.searchQuery = '',
    this.expandedSections = const {},
    this.isPlayingPreview = true,
  });

  final SubtitlePreset selectedPreset;
  final SubtitleConfiguration configuration;
  final bool isCustomized;
  final SubtitleCategory? selectedCategory;
  final String searchQuery;
  final Set<String> expandedSections;
  final bool isPlayingPreview;

  List<SubtitlePreset> get filteredPresets => SubtitlePresetsLibrary.search(
        query: searchQuery,
        category: selectedCategory,
      );

  SubtitleConfiguration get activeConfig => configuration;
  bool get isStyleSectionExpanded => expandedSections.contains('style');
  bool get isSettingsSectionExpanded => expandedSections.contains('settings');
  bool get isEffectsSectionExpanded => expandedSections.contains('effects');

  SubtitleStudioState copyWith({
    SubtitlePreset? selectedPreset,
    SubtitleConfiguration? configuration,
    bool? isCustomized,
    SubtitleCategory? selectedCategory,
    bool clearCategory = false,
    String? searchQuery,
    Set<String>? expandedSections,
    bool? isPlayingPreview,
  }) {
    return SubtitleStudioState(
      selectedPreset: selectedPreset ?? this.selectedPreset,
      configuration: configuration ?? this.configuration,
      isCustomized: isCustomized ?? this.isCustomized,
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      searchQuery: searchQuery ?? this.searchQuery,
      expandedSections: expandedSections ?? this.expandedSections,
      isPlayingPreview: isPlayingPreview ?? this.isPlayingPreview,
    );
  }
}

/// Riverpod notifier managing Subtitle Studio state.
class SubtitleStudioNotifier extends Notifier<SubtitleStudioState> {
  @override
  SubtitleStudioState build() {
    final defaultPreset = SubtitlePresetsLibrary.allPresets.first;
    return SubtitleStudioState(
      selectedPreset: defaultPreset,
      configuration: defaultPreset.toConfiguration(),
      expandedSections: const {},
    );
  }

  /// Toggles subtitles on / off globally across all previews.
  void setSubtitlesEnabled(bool enabled) {
    state = state.copyWith(
      configuration: state.configuration.copyWith(subtitlesEnabled: enabled),
      isCustomized: true,
    );
  }

  /// Selects a new preset from the library, preserving current canvas position.
  void selectPreset(SubtitlePreset preset) {
    final currentPos = state.configuration.position;
    state = state.copyWith(
      selectedPreset: preset,
      configuration: preset.toConfiguration(position: currentPos),
      isCustomized: false,
    );
  }

  /// Restores active configuration back to the original preset defaults.
  void resetToPreset() {
    final currentPos = state.configuration.position;
    state = state.copyWith(
      configuration: state.selectedPreset.toConfiguration(position: currentPos),
      isCustomized: false,
    );
  }

  /// Updates subtitle position from canvas drag or coordinate inputs.
  void updatePosition(double x, double y) {
    state = state.copyWith(
      configuration: state.configuration.copyWith(position: Offset(x, y)),
      isCustomized: true,
    );
  }

  void updatePositionOffset(Offset normalizedPosition) {
    state = state.copyWith(
      configuration: state.configuration.copyWith(position: normalizedPosition),
      isCustomized: true,
    );
  }

  void centerHorizontally() {
    updatePosition(0.5, state.configuration.position.dy);
  }

  void centerVertically() {
    updatePosition(state.configuration.position.dx, 0.5);
  }

  void centerBoth() {
    updatePosition(0.5, 0.5);
  }

  void toggleStyleSection() => toggleSection('style');
  void toggleSettingsSection() => toggleSection('settings');
  void toggleEffectsSection() => toggleSection('effects');

  void updateColors({
    Color? primaryTextColor,
    Color? highlightColor,
    Color? outlineColor,
    Color? shadowColor,
    Color? glowColor,
    Color? boxColor,
    Color? underlineColor,
  }) {
    updateColor(
      textColor: primaryTextColor,
      highlightColor: highlightColor,
      outlineColor: outlineColor,
      shadowColor: shadowColor,
      glowColor: glowColor,
      backgroundColor: boxColor,
      underlineColor: underlineColor,
    );
  }

  void updateTypography({
    String? fontFamily,
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? lineSpacing,
    bool? isUppercase,
    bool? isLowercase,
    double? textOpacity,
    TextAlign? textAlign,
  }) {
    state = state.copyWith(
      configuration: state.configuration.copyWith(
        fontFamily: fontFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        lineSpacing: lineSpacing,
        isUppercase: isUppercase,
        isLowercase: isLowercase,
        textOpacity: textOpacity,
        textAlign: textAlign,
      ),
      isCustomized: true,
    );
  }

  /// Updates Layer 1 entrance / text reveal animation settings.
  void updateLayer1({
    SubtitleLayer1Animation? animation,
    int? durationMs,
    int? delayMs,
    SubtitleEasing? easing,
    double? intensity,
    SubtitleAnimationDirection? direction,
  }) {
    state = state.copyWith(
      configuration: state.configuration.copyWith(
        layer1Animation: animation,
        layer1DurationMs: durationMs,
        layer1DelayMs: delayMs,
        layer1Easing: easing,
        layer1Intensity: intensity,
        layer1Direction: direction,
      ),
      isCustomized: true,
    );
  }

  /// Updates Layer 2 secondary motion and word emphasis animation settings.
  void updateLayer2({
    SubtitleLayer2Animation? animation,
    int? durationMs,
    int? delayMs,
    SubtitleEasing? easing,
    double? intensity,
    SubtitleAnimationDirection? direction,
  }) {
    state = state.copyWith(
      configuration: state.configuration.copyWith(
        layer2Animation: animation,
        layer2DurationMs: durationMs,
        layer2DelayMs: delayMs,
        layer2Easing: easing,
        layer2Intensity: intensity,
        layer2Direction: direction,
      ),
      isCustomized: true,
    );
  }

  /// Updates important word marker configuration.
  void updateMarker({
    SubtitleMarkerStyle? style,
    MarkerTexture? texture,
    Color? markerColor,
    double? thickness,
    double? distance,
    double? paddingH,
    double? paddingV,
    int? durationMs,
    double? opacity,
    MarkerAnimationBehavior? animation,
  }) {
    state = state.copyWith(
      configuration: state.configuration.copyWith(
        markerStyle: style,
        markerTexture: texture,
        markerColor: markerColor,
        markerThickness: thickness,
        markerDistance: distance,
        markerPaddingH: paddingH,
        markerPaddingV: paddingV,
        markerDurationMs: durationMs,
        markerOpacity: opacity,
        markerAnimation: animation,
      ),
      isCustomized: true,
    );
  }

  /// Updates marker texture selector.
  void updateMarkerTexture(MarkerTexture texture) {
    updateMarker(texture: texture);
  }

  void updateLineLayout({
    int? wordsPerLine,
    int? maxLines,
    TextAlign? textAlign,
  }) {
    state = state.copyWith(
      configuration: state.configuration.copyWith(
        wordsPerLine: wordsPerLine,
        maxLines: maxLines,
        textAlign: textAlign,
      ),
      isCustomized: true,
    );
  }

  void updateEmphasis({
    SubtitleEmphasisMode? emphasisMode,
    Color? boxColor,
    double? boxPadding,
    double? boxRadius,
    double? boxOpacity,
    Color? underlineColor,
    double? underlineThickness,
    double? underlineOffset,
    bool? dimInactiveWords,
    bool? translucentInactiveWords,
    double? inactiveWordTransparency,
  }) {
    Color? nextBgColor = boxColor;
    double? nextBgOpacity = boxOpacity;
    double? nextBgRadius = boxRadius;
    EdgeInsets? nextBgPadding = boxPadding != null
        ? EdgeInsets.symmetric(
            horizontal: boxPadding,
            vertical: (boxPadding * 0.45).clamp(2.0, 14.0),
          )
        : null;
    Color? nextUnderlineColor = underlineColor;
    double? nextUnderlineThickness = underlineThickness;
    double? nextUnderlineOffset = underlineOffset;
    bool? nextHasGlow;
    bool? nextHasOutline;
    Color? nextGlowColor;
    double? nextGlowIntensity;
    double? nextGlowBlur;
    double? nextOutlineWidth;

    if (emphasisMode == SubtitleEmphasisMode.boxedWord) {
      if (boxColor == null &&
          (state.configuration.backgroundColor == Colors.transparent ||
              state.configuration.backgroundColor.a == 0)) {
        nextBgColor = const Color(0xFF0F172A);
      }
      if (boxOpacity == null && state.configuration.backgroundOpacity <= 0.05) {
        nextBgOpacity = 0.85;
      }
      if (boxRadius == null && state.configuration.backgroundRadius <= 0) {
        nextBgRadius = 6.0;
      }
      if (boxPadding == null &&
          state.configuration.backgroundPadding.horizontal == 0) {
        nextBgPadding =
            const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5);
      }
    } else if (emphasisMode == SubtitleEmphasisMode.underline) {
      if (underlineColor == null &&
          (state.configuration.underlineColor == Colors.transparent ||
              state.configuration.underlineColor.a == 0)) {
        nextUnderlineColor = state.configuration.highlightColor;
      }
      if (underlineThickness == null &&
          state.configuration.underlineThickness <= 0) {
        nextUnderlineThickness = 3.0;
      }
      if (underlineOffset == null && state.configuration.underlineOffset <= 0) {
        nextUnderlineOffset = 3.0;
      }
    } else if (emphasisMode == SubtitleEmphasisMode.glowOutline) {
      nextHasGlow = true;
      nextHasOutline = true;
      if (state.configuration.glowColor == Colors.transparent ||
          state.configuration.glowColor.a == 0) {
        nextGlowColor = state.configuration.highlightColor;
      }
      if (state.configuration.glowIntensity <= 0.05) {
        nextGlowIntensity = 0.90;
      }
      if (state.configuration.glowBlur <= 1.0) {
        nextGlowBlur = 16.0;
      }
      if (state.configuration.outlineWidth <= 0) {
        nextOutlineWidth = 2.5;
      }
    }

    state = state.copyWith(
      configuration: state.configuration.copyWith(
        emphasisMode: emphasisMode,
        backgroundColor: nextBgColor,
        backgroundOpacity: nextBgOpacity,
        backgroundRadius: nextBgRadius,
        backgroundPadding: nextBgPadding,
        underlineColor: nextUnderlineColor,
        underlineThickness: nextUnderlineThickness,
        underlineOffset: nextUnderlineOffset,
        hasGlow: nextHasGlow,
        hasOutline: nextHasOutline,
        glowColor: nextGlowColor,
        glowIntensity: nextGlowIntensity,
        glowBlur: nextGlowBlur,
        outlineWidth: nextOutlineWidth,
        translucentInactiveWords: translucentInactiveWords,
        inactiveWordTransparency: inactiveWordTransparency,
        secondaryColor: dimInactiveWords != null
            ? (dimInactiveWords
                ? state.configuration.textColor.withValues(alpha: 0.45)
                : state.configuration.textColor)
            : null,
      ),
      isCustomized: true,
    );
  }

  void updateAnimations({
    SubtitleEntranceAnimation? entrance,
    SubtitleExitAnimation? exit,
  }) {
    state = state.copyWith(
      configuration: state.configuration.copyWith(
        entranceAnimation: entrance,
        exitAnimation: exit,
      ),
      isCustomized: true,
    );
  }

  /// Updates font size.
  void updateFontSize(double size) {
    state = state.copyWith(
      configuration: state.configuration.copyWith(fontSize: size),
      isCustomized: true,
    );
  }

  /// Updates words per line.
  void updateWordsPerLine(int count) {
    state = state.copyWith(
      configuration: state.configuration.copyWith(wordsPerLine: count),
      isCustomized: true,
    );
  }

  /// Updates font family.
  void updateFontFamily(String family) {
    state = state.copyWith(
      configuration: state.configuration.copyWith(fontFamily: family),
      isCustomized: true,
    );
  }

  /// Updates a specific color property.
  void updateColor({
    Color? textColor,
    Color? highlightColor,
    Color? outlineColor,
    Color? shadowColor,
    Color? glowColor,
    Color? backgroundColor,
    Color? underlineColor,
  }) {
    state = state.copyWith(
      configuration: state.configuration.copyWith(
        textColor: textColor,
        highlightColor: highlightColor,
        outlineColor: outlineColor,
        shadowColor: shadowColor,
        glowColor: glowColor,
        backgroundColor: backgroundColor,
        underlineColor: underlineColor,
      ),
      isCustomized: true,
    );
  }

  /// Updates effect parameters (glow, shadow, outline, etc.).
  void updateEffects({
    double? outlineWidth,
    bool? hasOutline,
    Color? outlineColor,
    double? shadowBlur,
    bool? hasShadow,
    Color? shadowColor,
    double? glowIntensity,
    double? glowBlur,
    bool? hasGlow,
    Color? glowColor,
    SubtitleEmphasisMode? emphasisMode,
    SubtitleEntranceAnimation? entranceAnimation,
    SubtitleExitAnimation? exitAnimation,
    Color? backgroundColor,
    double? backgroundOpacity,
    double? backgroundRadius,
    EdgeInsets? backgroundPadding,
    Color? underlineColor,
    double? underlineThickness,
    double? underlineOffset,
  }) {
    Color? nextGlowColor = glowColor;
    double? nextGlowIntensity = glowIntensity;
    double? nextGlowBlur = glowBlur;
    if (hasGlow == true) {
      if (glowColor == null &&
          (state.configuration.glowColor == Colors.transparent ||
              state.configuration.glowColor.a == 0)) {
        nextGlowColor = state.configuration.highlightColor;
      }
      if (glowIntensity == null && state.configuration.glowIntensity <= 0.05) {
        nextGlowIntensity = 0.85;
      }
      if (glowBlur == null && state.configuration.glowBlur <= 1.0) {
        nextGlowBlur = 14.0;
      }
    }

    Color? nextOutlineColor = outlineColor;
    if ((hasOutline == true || (outlineWidth != null && outlineWidth > 0)) &&
        outlineColor == null &&
        (state.configuration.outlineColor == Colors.transparent ||
            state.configuration.outlineColor.a == 0)) {
      nextOutlineColor = Colors.black;
    }

    Color? nextShadowColor = shadowColor;
    if ((hasShadow == true || (shadowBlur != null && shadowBlur > 0)) &&
        shadowColor == null &&
        (state.configuration.shadowColor == Colors.transparent ||
            state.configuration.shadowColor.a == 0)) {
      nextShadowColor = Colors.black54;
    }

    state = state.copyWith(
      configuration: state.configuration.copyWith(
        outlineWidth: outlineWidth,
        hasOutline: hasOutline,
        outlineColor: nextOutlineColor,
        shadowBlur: shadowBlur,
        hasShadow: hasShadow,
        shadowColor: nextShadowColor,
        glowIntensity: nextGlowIntensity,
        glowBlur: nextGlowBlur,
        hasGlow: hasGlow,
        glowColor: nextGlowColor,
        supportsGlow: hasGlow == true ? true : null,
        emphasisMode: emphasisMode,
        entranceAnimation: entranceAnimation,
        exitAnimation: exitAnimation,
        backgroundColor: backgroundColor,
        backgroundOpacity: backgroundOpacity,
        backgroundRadius: backgroundRadius,
        backgroundPadding: backgroundPadding,
        underlineColor: underlineColor,
        underlineThickness: underlineThickness,
        underlineOffset: underlineOffset,
      ),
      isCustomized: true,
    );
  }

  /// Filters presets by category.
  void setCategory(SubtitleCategory? category) {
    state = state.copyWith(
      selectedCategory: category,
      clearCategory: category == null,
    );
  }

  /// Updates search query string.
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Toggles accordion section expansion (STYLE, SETTINGS, EFFECTS).
  /// Single-expand mode: opening one section closes all other sections.
  void toggleSection(String sectionKey) {
    if (state.expandedSections.contains(sectionKey)) {
      state = state.copyWith(expandedSections: const {});
    } else {
      state = state.copyWith(expandedSections: {sectionKey});
    }
  }

  /// Sets preview animation playback explicitly.
  void setIsPlayingPreview(bool isPlaying) {
    state = state.copyWith(isPlayingPreview: isPlaying);
  }

  /// Toggles preview animation playback.
  void togglePlayPreview() {
    state = state.copyWith(isPlayingPreview: !state.isPlayingPreview);
  }

  /// Triggers a fresh replay of subtitle phrase animations.
  void replayAnimation() {
    state = state.copyWith(isPlayingPreview: false);
    Future.microtask(() {
      state = state.copyWith(isPlayingPreview: true);
    });
  }
}

/// Global provider for Subtitle Studio state.
final subtitleStudioProvider =
    NotifierProvider<SubtitleStudioNotifier, SubtitleStudioState>(
  SubtitleStudioNotifier.new,
);
