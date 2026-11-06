import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/branding_models.dart';

const _uuid = Uuid();

/// Riverpod provider for Stage 5: Branding & Overlay Studio.
final brandingProvider =
    NotifierProvider<BrandingNotifier, BrandingStudioState>(
  BrandingNotifier.new,
);

class BrandingNotifier extends Notifier<BrandingStudioState> {
  @override
  BrandingStudioState build() {
    // User requested: do NOT auto add anything. Start empty so user presses + Add.
    return const BrandingStudioState(
      activeTab: BrandingTab.permanent,
      permanentLayers: [],
      selectedPermanentId: null,
      temporaryOverlays: [],
      selectedTemporaryId: null,
      timelineScrubPercent: 0.0,
      clipDurationSeconds: 30.0,
    );
  }

  // ── Tab Navigation ─────────────────────────────────────────────────────────

  void setTab(BrandingTab tab) {
    state = state.copyWith(activeTab: tab);
  }

  // ── Interactive Timeline Scrubber ──────────────────────────────────────────

  void setTimelineScrubPercent(double percent) {
    final clamped = percent.clamp(0.0, 100.0);
    state = state.copyWith(timelineScrubPercent: clamped);
  }

  void setClipDurationSeconds(double duration) {
    if (duration > 0) {
      state = state.copyWith(clipDurationSeconds: duration);
    }
  }

  // ── Permanent Branding Layer Management ────────────────────────────────────

  void addPermanentLayer({String text = 'BRANDING TEXT'}) {
    final newId = _uuid.v4();
    final newLayer = BrandingLayer(
      id: newId,
      text: text,
      font: 'Montserrat',
      fontSize: 22.0,
      fontWeight: FontWeight.w700,
      textColor: Colors.white,
      opacity: 0.9,
      position: PositionPreset.topRight,
      alignment: TextAlign.center,
      startPercent: 0.0,
      endPercent: 100.0,
      appearAnimation: AppearAnimationType.fadeIn,
      continuousAnimation: ContinuousAnimationType.none,
    );

    state = state.copyWith(
      permanentLayers: [...state.permanentLayers, newLayer],
      selectedPermanentId: newId,
    );
  }

  void selectPermanentLayer(String id) {
    if (state.permanentLayers.any((l) => l.id == id)) {
      state = state.copyWith(selectedPermanentId: id);
    }
  }

  void updatePermanentLayer(
    String id,
    BrandingLayer Function(BrandingLayer current) updater,
  ) {
    state = state.copyWith(
      permanentLayers: state.permanentLayers.map((layer) {
        if (layer.id == id) {
          return updater(layer);
        }
        return layer;
      }).toList(),
    );
  }

  void deletePermanentLayer(String id) {
    final remaining = state.permanentLayers.where((l) => l.id != id).toList();
    String? newSelectedId = state.selectedPermanentId;
    if (newSelectedId == id) {
      newSelectedId = remaining.isNotEmpty ? remaining.last.id : null;
    }
    state = state.copyWith(
      permanentLayers: remaining,
      selectedPermanentId: newSelectedId,
    );
  }

  void duplicatePermanentLayer(String id) {
    final index = state.permanentLayers.indexWhere((l) => l.id == id);
    if (index == -1) return;

    final original = state.permanentLayers[index];
    final newId = _uuid.v4();
    final duplicate = original.copyWith(
      id: newId,
      text: '${original.text} (Copy)',
      fineOffsetX: original.fineOffsetX + 10.0,
      fineOffsetY: original.fineOffsetY + 10.0,
    );

    final updated = List<BrandingLayer>.from(state.permanentLayers);
    updated.insert(index + 1, duplicate);

    state = state.copyWith(
      permanentLayers: updated,
      selectedPermanentId: newId,
    );
  }

  void reorderPermanentLayers(int oldIndex, int targetIndex) {
    if (oldIndex < 0 || oldIndex >= state.permanentLayers.length) return;
    if (targetIndex < 0 || targetIndex >= state.permanentLayers.length) return;
    if (oldIndex == targetIndex) return;

    final updated = List<BrandingLayer>.from(state.permanentLayers);
    final moved = updated.removeAt(oldIndex);
    updated.insert(targetIndex, moved);

    state = state.copyWith(permanentLayers: updated);
  }

  void resetPermanentLayer(String id) {
    updatePermanentLayer(
      id,
      (current) => BrandingLayer(
        id: current.id,
        text: current.text,
        font: 'Montserrat',
        fontSize: 22.0,
        fontWeight: FontWeight.w700,
        italic: false,
        letterSpacing: 1.5,
        lineSpacing: 1.2,
        textColor: Colors.white,
        underline: false,
        strikethrough: false,
        shadow: true,
        shadowIntensity: 0.65,
        shadowDistance: 2.5,
        shadowSoftness: 4.0,
        glow: false,
        glowIntensity: 0.8,
        glowColor: const Color(0xFF8B5CF6),
        neon: false,
        opacity: 1.0,
        position: PositionPreset.bottomRight,
        fineOffsetX: 0.0,
        fineOffsetY: 0.0,
        alignment: TextAlign.center,
        startPercent: 0.0,
        endPercent: 100.0,
        appearAnimation: AppearAnimationType.fadeIn,
        continuousAnimation: ContinuousAnimationType.none,
      ),
    );
  }

  // ── Temporary Overlay Management ───────────────────────────────────────────

  void addTemporaryOverlay({
    OverlayStylePreset style = OverlayStylePreset.verticalLineRight,
  }) {
    final newId = _uuid.v4();
    final count = state.temporaryOverlays.length + 1;
    final name = 'Overlay ${count.toString().padLeft(2, '0')}';

    final isLineLeft = style == OverlayStylePreset.verticalLineLeft;
    final isLineRight = style == OverlayStylePreset.verticalLineRight;

    final newOverlay = TemporaryOverlay(
      id: newId,
      name: name,
      text: 'VIRAL HOOK',
      font: 'Montserrat',
      fontSize: 20.0,
      fontWeight: FontWeight.w800,
      style: style,
      shape: style.defaultShape,
      shapeColor: const Color(0xFF8B5CF6),
      shapeSize: 40.0,
      lineLength: 80.0,
      borderThickness: 2.5,
      borderStyle: OverlayBorderStyle.solid,
      cornerRadius: 8.0,
      fill: true,
      fillColor: const Color(0x338B5CF6),
      position: style.defaultPosition,
      alignment: isLineRight
          ? TextAlign.right
          : (isLineLeft ? TextAlign.left : TextAlign.center),
      startPercent: 20.0,
      endPercent: 65.0,
      appearAnimation: AppearAnimationType.slideInUp,
      exitAnimation: ExitAnimationType.slideOutDown,
      continuousAnimation: ContinuousAnimationType.glowPulse,
      animationDuration: 0.5,
      exitDuration: 0.5,
    );

    state = state.copyWith(
      temporaryOverlays: [...state.temporaryOverlays, newOverlay],
      selectedTemporaryId: newId,
    );
  }

  void selectTemporaryOverlay(String id) {
    if (state.temporaryOverlays.any((o) => o.id == id)) {
      state = state.copyWith(selectedTemporaryId: id);
    }
  }

  void updateTemporaryOverlay(
    String id,
    TemporaryOverlay Function(TemporaryOverlay current) updater,
  ) {
    state = state.copyWith(
      temporaryOverlays: state.temporaryOverlays.map((overlay) {
        if (overlay.id == id) {
          return updater(overlay);
        }
        return overlay;
      }).toList(),
    );
  }

  void deleteTemporaryOverlay(String id) {
    final remaining = state.temporaryOverlays.where((o) => o.id != id).toList();
    String? newSelectedId = state.selectedTemporaryId;
    if (newSelectedId == id) {
      newSelectedId = remaining.isNotEmpty ? remaining.last.id : null;
    }
    state = state.copyWith(
      temporaryOverlays: remaining,
      selectedTemporaryId: newSelectedId,
    );
  }

  void duplicateTemporaryOverlay(String id) {
    final index = state.temporaryOverlays.indexWhere((o) => o.id == id);
    if (index == -1) return;

    final original = state.temporaryOverlays[index];
    final newId = _uuid.v4();
    final count = state.temporaryOverlays.length + 1;
    final duplicate = original.copyWith(
      id: newId,
      name: 'Overlay ${count.toString().padLeft(2, '0')}',
      fineOffsetX: original.fineOffsetX + 10.0,
      fineOffsetY: original.fineOffsetY + 10.0,
    );

    final updated = List<TemporaryOverlay>.from(state.temporaryOverlays);
    updated.insert(index + 1, duplicate);

    state = state.copyWith(
      temporaryOverlays: updated,
      selectedTemporaryId: newId,
    );
  }

  void reorderTemporaryOverlays(int oldIndex, int targetIndex) {
    if (oldIndex < 0 || oldIndex >= state.temporaryOverlays.length) return;
    if (targetIndex < 0 || targetIndex >= state.temporaryOverlays.length) return;
    if (oldIndex == targetIndex) return;

    final updated = List<TemporaryOverlay>.from(state.temporaryOverlays);
    final moved = updated.removeAt(oldIndex);
    updated.insert(targetIndex, moved);

    state = state.copyWith(temporaryOverlays: updated);
  }

  void changeOverlayStyle(String id, OverlayStylePreset newStyle) {
    updateTemporaryOverlay(id, (current) {
      final isLineLeft = newStyle == OverlayStylePreset.verticalLineLeft;
      final isLineRight = newStyle == OverlayStylePreset.verticalLineRight;

      return current.copyWith(
        style: newStyle,
        shape: newStyle.defaultShape,
        position: newStyle.defaultPosition,
        alignment: isLineRight
            ? TextAlign.right
            : (isLineLeft ? TextAlign.left : TextAlign.center),
      );
    });
  }

  void resetTemporaryOverlay(String id) {
    updateTemporaryOverlay(id, (current) {
      final style = current.style;
      final isLineLeft = style == OverlayStylePreset.verticalLineLeft;
      final isLineRight = style == OverlayStylePreset.verticalLineRight;

      return TemporaryOverlay(
        id: current.id,
        name: current.name,
        text: current.text,
        font: 'Montserrat',
        fontSize: 20.0,
        fontWeight: FontWeight.w800,
        italic: false,
        letterSpacing: 1.0,
        lineSpacing: 1.2,
        textColor: Colors.white,
        underline: false,
        strikethrough: false,
        shadow: true,
        shadowIntensity: 0.6,
        shadowDistance: 2.5,
        shadowSoftness: 4.0,
        glow: true,
        glowIntensity: 0.75,
        glowColor: const Color(0xFF8B5CF6),
        neon: false,
        style: style,
        shape: style.defaultShape,
        shapeColor: const Color(0xFF8B5CF6),
        shapeSize: 40.0,
        lineLength: 80.0,
        borderThickness: 2.5,
        borderStyle: OverlayBorderStyle.solid,
        cornerRadius: 8.0,
        fill: true,
        fillColor: const Color(0x338B5CF6),
        position: style.defaultPosition,
        fineOffsetX: 0.0,
        fineOffsetY: 0.0,
        alignment: isLineRight
            ? TextAlign.right
            : (isLineLeft ? TextAlign.left : TextAlign.center),
        startPercent: current.startPercent,
        endPercent: current.endPercent,
        appearAnimation: AppearAnimationType.slideInUp,
        exitAnimation: ExitAnimationType.slideOutDown,
        continuousAnimation: ContinuousAnimationType.glowPulse,
        animationDuration: 0.5,
        exitDuration: 0.5,
      );
    });
  }
}
