import 'package:flutter/material.dart';

import '../models/editing_effect.dart';

/// Catalogue of the 10 high-energy Creator Editing Effects for ClipIt Step 4.
///
/// NOTE: The [id] (e.g. CLP_FX_RAGE_SCREEN) is internal only and NEVER shown anywhere in the UI.
class EffectCatalogue {
  EffectCatalogue._();

  static const List<EditingEffect> allEffects = [
    // ── 1. RAGE SCREEN ───────────────────────────────────────────────────────
    EditingEffect(
      id: 'CLP_FX_RAGE_SCREEN',
      name: 'RAGE SCREEN',
      category: EffectCategory.aura,
      shortDescription: 'Aggressive red tint, screen shake, pulse & animated embers',
      visualDirection: 'Aggressive red-tinted screen + subtle dark/red vignette + animated red particles + screen shake + quick brightness pulse',
      recipeLayers: [
        EffectRecipeLayer(name: 'Aggressive Red Color Grade', layerType: 'grade'),
        EffectRecipeLayer(name: 'Camera Jolt & Pulse', layerType: 'timing'),
        EffectRecipeLayer(name: 'Swirling Red Ember Fury', layerType: 'overlay'),
        EffectRecipeLayer(name: 'Deep Crimson Vignette', layerType: 'grade'),
      ],
      isTrending: true,
      accentColor: Color(0xFFEF4444),
      badgeText: 'RAGE',
      badgeIcon: Icons.local_fire_department_rounded,
    ),

    // ── 2. RED PARTICLE STORM ────────────────────────────────────────────────
    EditingEffect(
      id: 'CLP_FX_RED_PARTICLE_STORM',
      name: 'RED PARTICLE STORM',
      category: EffectCategory.aura,
      shortDescription: 'Hundreds of moving red depth particles with subtle glow',
      visualDirection: 'Hundreds of dynamic red particles drifting with depth, variable speeds, subtle blur and glow',
      recipeLayers: [
        EffectRecipeLayer(name: 'Multi-layer Depth Particles', layerType: 'overlay'),
        EffectRecipeLayer(name: 'Soft Particle Glow & Blur', layerType: 'overlay'),
        EffectRecipeLayer(name: 'Wind Turbulence Motion', layerType: 'timing'),
      ],
      isTrending: true,
      accentColor: Color(0xFFF43F5E),
      badgeText: 'STORM',
      badgeIcon: Icons.grain_rounded,
    ),

    // ── 3. RED FILTER ────────────────────────────────────────────────────────
    EditingEffect(
      id: 'CLP_FX_RED_FILTER',
      name: 'RED FILTER',
      category: EffectCategory.character,
      shortDescription: 'Strong cinematic red color grade with enhanced contrast',
      visualDirection: 'Strong red color grade + preserved underlying video + increased contrast + subtle vignette',
      recipeLayers: [
        EffectRecipeLayer(name: 'Rich Crimson Color Grade', layerType: 'grade'),
        EffectRecipeLayer(name: 'Contrast & Highlight Boost', layerType: 'grade'),
        EffectRecipeLayer(name: 'Subtle Perimeter Vignette', layerType: 'grade'),
      ],
      isTrending: false,
      accentColor: Color(0xFFDC2626),
      badgeText: 'RED',
      badgeIcon: Icons.filter_b_and_w_rounded,
    ),

    // ── 4. GOLDEN / OP FILTER ────────────────────────────────────────────────
    EditingEffect(
      id: 'CLP_FX_GOLDEN_OP',
      name: 'GOLDEN / OP',
      category: EffectCategory.character,
      shortDescription: 'Golden "I\'m HIM / OP" grade, warm highlights & floating dust',
      visualDirection: 'Golden color grade + warm highlights + increased contrast + golden glow & bloom + floating golden particles',
      recipeLayers: [
        EffectRecipeLayer(name: 'Warm Golden Color Grade', layerType: 'grade'),
        EffectRecipeLayer(name: 'Specular Golden Bloom', layerType: 'overlay'),
        EffectRecipeLayer(name: 'Floating Gold Sparkles', layerType: 'overlay'),
        EffectRecipeLayer(name: 'Cinematic Framing Vignette', layerType: 'grade'),
      ],
      isTrending: true,
      accentColor: Color(0xFFF59E0B),
      badgeText: 'OP MOMENT',
      badgeIcon: Icons.star_rounded,
    ),

    // ── 5. CROWN MOMENT ──────────────────────────────────────────────────────
    EditingEffect(
      id: 'CLP_FX_CROWN',
      name: 'CROWN MOMENT',
      category: EffectCategory.face,
      shortDescription: 'Tracked golden crown following head pose, scale & tilt',
      visualDirection: 'Transparent golden crown graphic tracked to head position, tilt and size with subtle glow and particles',
      recipeLayers: [
        EffectRecipeLayer(name: 'Face & Head Pose Tracking', layerType: 'tracked'),
        EffectRecipeLayer(name: 'Golden Crown Graphic', layerType: 'graphic'),
        EffectRecipeLayer(name: 'Crown Ambient Glow & Particles', layerType: 'overlay'),
      ],
      requiresFaceTracking: true,
      isTrending: true,
      accentColor: Color(0xFFFBBF24),
      badgeText: 'CROWN',
      badgeIcon: Icons.workspace_premium_rounded,
    ),

    // ── 6. FIRE AURA ─────────────────────────────────────────────────────────
    EditingEffect(
      id: 'CLP_FX_FIRE_AURA',
      name: 'FIRE AURA',
      category: EffectCategory.aura,
      shortDescription: 'Animated flame perimeter, warm glow & energetic sparks',
      visualDirection: 'Animated fire and flame particles along frame edges + warm glow + small sparks + darkened fiery edges',
      recipeLayers: [
        EffectRecipeLayer(name: 'Perimeter Flame Particles', layerType: 'overlay'),
        EffectRecipeLayer(name: 'Rising Heat Sparks', layerType: 'overlay'),
        EffectRecipeLayer(name: 'Fiery Rim Vignette', layerType: 'grade'),
      ],
      isTrending: true,
      accentColor: Color(0xFFFF6B00),
      badgeText: 'FIRE',
      badgeIcon: Icons.whatshot_rounded,
    ),

    // ── 7. LIGHTNING FLASH ───────────────────────────────────────────────────
    EditingEffect(
      id: 'CLP_FX_LIGHTNING',
      name: 'LIGHTNING FLASH',
      category: EffectCategory.digital,
      shortDescription: 'Sudden electric lightning strikes, brightness spike & sparks',
      visualDirection: 'Quick white/lightning flash + branching lightning graphics + subtle glow + brightness pulse + particle burst',
      recipeLayers: [
        EffectRecipeLayer(name: 'Branching Lightning Bolts', layerType: 'overlay'),
        EffectRecipeLayer(name: 'Impact Brightness Pulse', layerType: 'timing'),
        EffectRecipeLayer(name: 'Electric Discharge Glow', layerType: 'overlay'),
      ],
      isTrending: false,
      accentColor: Color(0xFF60A5FA),
      badgeText: 'LIGHTNING',
      badgeIcon: Icons.bolt_rounded,
    ),

    // ── 8. CINEMATIC BLACK & WHITE ───────────────────────────────────────────
    EditingEffect(
      id: 'CLP_FX_CINEMATIC_BW',
      name: 'CINEMATIC B&W',
      category: EffectCategory.character,
      shortDescription: 'High-contrast monochrome grade, crushed blacks & grain',
      visualDirection: 'Actual black-and-white color processing + increased contrast + slightly crushed blacks + subtle film grain + vignette',
      recipeLayers: [
        EffectRecipeLayer(name: 'High-Contrast Monochrome Grade', layerType: 'grade'),
        EffectRecipeLayer(name: 'Deep Crushed Shadows', layerType: 'grade'),
        EffectRecipeLayer(name: 'Subtle 35mm Film Grain', layerType: 'overlay'),
        EffectRecipeLayer(name: 'Theatrical Vignette', layerType: 'grade'),
      ],
      isTrending: false,
      accentColor: Color(0xFFE5E7EB),
      badgeText: 'B&W',
      badgeIcon: Icons.contrast_rounded,
    ),

    // ── 9. GLITCH / CHROMATIC ────────────────────────────────────────────────
    EditingEffect(
      id: 'CLP_FX_GLITCH',
      name: 'GLITCH / CHROMATIC',
      category: EffectCategory.digital,
      shortDescription: 'RGB chromatic separation, horizontal displacement & scanlines',
      visualDirection: 'RGB chromatic separation + brief horizontal distortion bursts + digital displacement + scanline texture + glitch flashes',
      recipeLayers: [
        EffectRecipeLayer(name: 'RGB Chromatic Separation', layerType: 'grade'),
        EffectRecipeLayer(name: 'Digital Slice Displacement', layerType: 'overlay'),
        EffectRecipeLayer(name: 'CRT Scanline Texture', layerType: 'overlay'),
      ],
      isTrending: true,
      accentColor: Color(0xFF06B6D4),
      badgeText: 'GLITCH',
      badgeIcon: Icons.splitscreen_rounded,
    ),

    // ── 10. EMOJI / CONFETTI BURST ───────────────────────────────────────────
    EditingEffect(
      id: 'CLP_FX_EMOJI_BURST',
      name: 'EMOJI BURST',
      category: EffectCategory.meme,
      shortDescription: 'Celebratory burst of emojis, confetti ribbons & particles',
      visualDirection: 'Colorful emoji-style particles + confetti bursting outward from center with rotation, gravity physics and natural fade',
      recipeLayers: [
        EffectRecipeLayer(name: 'Radial Emoji Particle Emitter', layerType: 'overlay'),
        EffectRecipeLayer(name: 'Fluttering Confetti Ribbons', layerType: 'overlay'),
        EffectRecipeLayer(name: 'Celebratory Sparkle Burst', layerType: 'overlay'),
      ],
      isTrending: true,
      accentColor: Color(0xFFEC4899),
      badgeText: 'CELEBRATE',
      badgeIcon: Icons.celebration_rounded,
    ),
  ];

  /// Find effect by internal code.
  static EditingEffect? findById(String id) {
    for (final effect in allEffects) {
      if (effect.id == id) return effect;
    }
    return null;
  }
}
