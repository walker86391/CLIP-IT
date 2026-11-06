import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/subtitle_studio_provider.dart';
import 'subtitle_phrase_renderer.dart';

/// Read-only, immovable subtitle overlay that sticks to the phone screen
/// across downstream editing stages (Video Look, Sound Effects, Visual Effects, Overlays).
///
/// Retains exact position (X & Y), typography, scale, and animated word preview.
/// Ignores pointer events so it cannot be dragged, resized, or selected outside
/// the Subtitle Studio (user must return to Subtitles to edit).
class ImmovableSubtitleOverlay extends ConsumerWidget {
  const ImmovableSubtitleOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studioState = ref.watch(subtitleStudioProvider);
    final config = studioState.activeConfig;

    if (!config.subtitlesEnabled) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasW = constraints.maxWidth;
        final canvasH = constraints.maxHeight;

        final posX = config.positionX * canvasW;
        final posY = config.positionY * canvasH;

        return IgnorePointer(
          ignoring: true,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: posX,
                top: posY,
                child: FractionalTranslation(
                  translation: const Offset(-0.5, -0.5),
                  child: SubtitlePhraseRenderer(
                    config: config,
                    isAnimated: true,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
