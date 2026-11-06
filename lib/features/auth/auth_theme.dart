import 'package:flutter/material.dart';

/// Visual tokens for the Loading + Auth milestone (medium-dark gray theme).
///
/// Scoped to the auth flow on purpose — the main app keeps its own
/// token system in lib/ui/tokens. Values come from the milestone spec:
/// bg #14161B, text #E7E9ED, secondary #B7BCC6, accent #6EA8FE, error
/// #FF6666, glass = white 6% fill / white 10% border / blur 24–28.
abstract final class AuthColors {
  // ── Base ────────────────────────────────────────────────────────────────
  static const Color background = Color(0xFF14161B);
  static const Color textPrimary = Color(0xFFE7E9ED);
  static const Color textSecondary = Color(0xFFB7BCC6);
  static const Color accent = Color(0xFF6EA8FE);
  static const Color error = Color(0xFFFF6666);

  // Accent states (hover/pressed) — derived, kept explicit for clarity.
  static const Color accentHover = Color(0xFF85B7FF);
  static const Color accentPressed = Color(0xFF5A93E8);

  // ── Glass panel ─────────────────────────────────────────────────────────
  /// White at 6% opacity.
  static const Color glassFill = Color(0x0FFFFFFF);

  /// White at 10% opacity (1px border).
  static const Color glassBorder = Color(0x1AFFFFFF);

  /// Backdrop blur sigma for the panel (spec: 24–28 px).
  static const double glassBlurSigma = 26;

  static const double panelRadius = 16;
  static const double panelWidth = 520;

  /// Subtle shadow: 12% black, 24 px blur.
  static const Color panelShadow = Color(0x1F000000); // ~12% black
  static const double panelShadowBlur = 24;

  // ── Inputs (Apple-style glass field, single unified surface) ───────────
  //
  // History: the text fields used to be a flat white-8% box with a
  // white-12% border. Over the panel (itself white 6% on blurred photo)
  // that stacked into a milky grey slab — the user called it "the grey
  // thing". The tokens below build ONE smooth glass surface instead: a
  // barely-there fill gradient (bright sheen at the top edge fading into a
  // near-clear base) plus a 1px hairline border painted by
  // ChromaticGlassBorderPainter with red/cyan chromatic-aberration fringes
  // for the lens-glass look.
  //
  // NOTE: the older flat fill/border tokens that were used for the grey
  // text-field look are kept below because the CHECKBOX and the SEGMENTED
  // TABS still use them for their own small control surfaces — only the
  // text fields moved to the new glass treatment.

  /// Top edge of the fill gradient — white at ~9% (the specular sheen).
  static const Color fieldGlassFillTop = Color(0x17FFFFFF);

  /// Base of the fill gradient — white at ~3.5% (barely darker than the
  /// panel itself, so the field reads as shaped glass, not a grey layer).
  static const Color fieldGlassFillBase = Color(0x09FFFFFF);

  /// Bottom of the fill gradient — white at ~4.5% (a hint darker than the
  /// base so the surface has gentle depth without looking layered).
  static const Color fieldGlassFillBottom = Color(0x0CFFFFFF);

  /// Hover variants — one small step brighter, same gradient shape.
  static const Color fieldGlassFillTopHover = Color(0x1FFFFFFF);
  static const Color fieldGlassFillBaseHover = Color(0x0DFFFFFF);
  static const Color fieldGlassFillBottomHover = Color(0x11FFFFFF);

  /// Hairline border gradient (top of the edge) — white at ~20%.
  static const Color fieldGlassBorderTop = Color(0x33FFFFFF);

  /// Hairline border gradient (bottom of the edge) — white at ~6%.
  static const Color fieldGlassBorderBottom = Color(0x10FFFFFF);

  /// Focused hairline border — accent, full strength at the top edge.
  static const Color fieldGlassBorderFocus = Color(0xFF6EA8FE);

  /// Error hairline border — error red at the top edge.
  static const Color fieldGlassBorderError = Color(0xFFFF6666);

  // ── Legacy flat fill/border (still used by checkbox + segmented tabs) ─
  /// White at ~8% — flat surface fill for small controls (NOT text
  /// fields any more, see the history note above).
  static const Color fieldFill = Color(0x14FFFFFF);

  /// White at ~12% — hairline for small controls.
  static const Color fieldBorder = Color(0x1FFFFFFF);

  /// White at ~30% — unchecked checkbox outline.
  static const Color fieldBorderStrong = Color(0x4DFFFFFF);

  // ── Chromatic aberration (the "lens glass" edge shimmer) ───────────────
  //
  // Apple's liquid-glass surfaces show a faint red/cyan split along their
  // edges, like light dispersing through real glass. We paint the border
  // path three times: red shifted slightly left, cyan slightly right, and
  // the white hairline on top. Keep the shift tiny (sub-pixel) and the
  // alpha low — this must read as shimmer, not neon outlining.

  /// Horizontal offset of the aberration fringes, in logical pixels.
  static const double glassAberrationShift = 0.7;

  /// Alpha of the fringe strokes (0..1). Subtle on purpose.
  static const double glassAberrationOpacity = 0.30;

  /// Red fringe (Apple system red), used for the left-shifted copy.
  static const Color aberrationRed = Color(0xFFFF453A);

  /// Cyan fringe (Apple system cyan), used for the right-shifted copy.
  static const Color aberrationCyan = Color(0xFF64D2FF);

  // ── Magnetic button feel ────────────────────────────────────────────────
  //
  // The primary Continue button is "magnetic": while the cursor is within
  // an invisible hit margin around the button, the button eases toward the
  // cursor by a fraction of the cursor-to-center distance, and springs
  // back to rest when the cursor leaves.

  /// Fraction of the cursor-to-center distance the button follows.
  ///
  /// Reduced from 0.22 → 0.12 on user request: the original pull was too
  /// eager and made the button feel like it was chasing the cursor.
  static const double magneticPull = 0.12;

  /// Hard cap on the translate distance so the button never detaches
  /// visually from its layout slot (reduced 7 → 4 with the pull above).
  static const double magneticMaxOffset = 4.0;

  /// How far OUTSIDE the button's edge the magnetic field still reaches,
  /// in logical pixels. The pull fades smoothly to zero across this band
  /// (easeOutCubic), so there is no visible pop when the cursor crosses
  /// the field boundary. Reduced 64 → 48 so the effect stays close to the
  /// button instead of reaching across the form.
  static const double magneticReach = 48;

  /// How fast the button chases a moving cursor.
  static const Duration magneticChaseDuration = Duration(milliseconds: 140);

  /// How fast the button springs back when the cursor leaves. The curve
  /// used on return is Curves.easeOutBack for a soft overshoot "snap".
  static const Duration magneticReturnDuration = Duration(milliseconds: 260);

  // ── Submit tick (replaces the Continue button) ─────────────────────────
  //
  // The primary action is now a compact square tick instead of a wide
  // "Continue" button: a blue rounded square with a dark tick inside once
  // the form is complete, grey-on-glass while anything is still missing.

  /// Edge length of the square submit control.
  static const double submitTickSize = 52;

  /// Corner radius of the square.
  static const double submitTickRadius = 16;

  /// Glass fill while the form is incomplete (white ~6%, like the panel).
  static const Color submitTickDisabledFill = Color(0x0FFFFFFF);

  /// Hairline while the form is incomplete (white ~12%).
  static const Color submitTickDisabledBorder = Color(0x1FFFFFFF);

  /// The tick mark while disabled — secondary grey, dimmed so it reads as
  /// "not yet available" rather than as a real control.
  static const Color submitTickDisabledMark = Color(0x8CB7BCC6);

  /// Accent blue once the form is complete.
  static const Color submitTickEnabledFill = Color(0xFF6EA8FE);

  /// Slightly lighter blue on hover, same as the old button's hover state.
  static const Color submitTickEnabledHover = Color(0xFF85B7FF);

  /// The tick mark inside the enabled (blue) square — dark, for contrast.
  static const Color submitTickMark = Color(0xFF14161B);

  /// Scale while the control is held down.
  static const double submitTickPressScale = 0.88;

  // ── Agreement checkbox bounce ──────────────────────────────────────────
  //
  // The two agreement boxes get a very small bounce when ticked, so the tap
  // registers even though the change itself is only a colour swap.
  static const double checkboxTickBounceScale = 0.86;

  // ── Focus / misc ────────────────────────────────────────────────────────
  /// Accent at 40% — keyboard focus ring.
  static const Color focusRing = Color(0x666EA8FE);

  /// White pill on the segmented tabs.
  static const Color tabPill = Color(0x1FFFFFFF);

  /// Max strength of the right-side dark scrim (keeps image shape visible).
  static const double scrimMaxOpacity = 0.25;

  // ── Background blur ────────────────────────────────────────────────────
  /// Blur applied to the RIGHT side of the background image, behind the
  /// glass panel. The left side of the window is left sharp.
  ///
  /// Design history (kept for future iterations):
  ///
  ///   v1 — 12 strips ramping sigma 2 → 26 across the WHOLE zone. The user
  ///        rejected it: "progressive blur is bad" (read as a smear).
  ///   v2 — one full-screen flat blur. The user rejected it: only the right
  ///        part should blur.
  ///   v3 — right-side zone, ONE flat sigma. The user liked the flat bulk
  ///        but the zone's left boundary was a hard vertical line: "the
  ///        line where the blur starts is too sharp".
  ///   v4 (current) — flat bulk PRESERVED, but the left boundary is now a
  ///        feather: a narrow band of thin strips whose sigma eases in from
  ///        ~0 to the full value over [backgroundBlurFeatherWidth] px, with
  ///        the dark scrim fading over the same band. Only the boundary
  ///        line is diffused; the bulk stays flat, per the v3 feedback.
  ///
  /// The bulk value is a little high on purpose: the panel text has to
  /// stay comfortably readable over it.
  static const double backgroundBlurSigma = 18;

  /// Width of the soft feather band at the blur zone's LEFT edge, in
  /// logical pixels. This is the region where the blur eases in from
  /// sharp to full strength, replacing the hard cutoff line.
  ///
  /// Kept just under [backgroundBlurMargin] so the full-strength blur is
  /// already reached by the time the ramp reaches the glass panel.
  static const double backgroundBlurFeatherWidth = 88;

  /// How many discrete strips tile the feather band. Each strip is
  /// [backgroundBlurFeatherWidth] / N px wide and applies one sigma step.
  ///
  /// 32 strips (≈2.75 px each) instead of the original 12: at 12 the sigma
  /// jump between neighbours was large enough near the full-blur end that
  /// the band read as visible STAIRS ("a bit low, a bit high") rather than
  /// a smooth ramp. ~0.65 sigma per step at the steepest point is below
  /// what the eye can separate.
  static const int backgroundBlurFeatherSteps = 32;

  /// Ease-in power applied to the feather ramp (sigma ∝ (i/N)^power).
  /// A power above 1 keeps the first steps nearly sharp, so the transition
  /// BEGINS imperceptibly — that is what kills the visible "line where the
  /// blur starts". Lowered 1.35 → 1.15 so the ramp is more evenly
  /// distributed (a steeper power bunches many steps at the blurred end,
  /// which is exactly where the banding was visible).
  static const double backgroundBlurFeatherEase = 1.15;

  /// Dark wash over the blurred right-hand zone so the glass panel always has
  /// enough contrast behind it. Scoped to the same zone as the blur — NOT
  /// the full screen.
  ///
  /// v4: the wash is a horizontal GRADIENT that fades in across the same
  /// feather band as the blur (transparent at the zone's left edge, full
  /// strength where the blur reaches full sigma, flat to the right edge).
  /// A flat wash would draw its own hard edge line, defeating the feather.
  static const double backgroundScrimOpacity = 0.28;

  // ── Blur zone placement ────────────────────────────────────────────────
  //
  // The zone is no longer a fixed 55% of the window anchored to the right
  // edge. The user asked for it to (a) start further to the right, so more
  // of the forest photo (which has writing in it) stays sharp, and (b) sit
  // centred on the glass panel so the panel has an equal band of softened
  // image on both sides.
  //
  // (b) is expressed as: margin = (zoneWidth - panelWidth) / 2, with the
  // zone centred on the panel. At a 1280px window that is
  // (704 - 520) / 2 = 92px of margin per side.
  static const double backgroundBlurMarginFraction = 0.5;

  // ── Panel metrics (used to place the blur zone) ────────────────────────
  //
  // The glass panel's own inner padding, and the segmented tabs' padding +
  // border, are needed to derive the width of the sliding selection pill.
  static const double panelInnerPadding = 32;

  /// Horizontal padding between the panel and the window edge.
  static const double panelOuterPadding = 48;

  static const double tabsPadding = 3;

  static const double tabsBorderWidth = 1;

  // ── Background image ────────────────────────────────────────────────────
  /// Forest-style background. Source: the user's input resources folder,
  /// copied into the project at build time (the original folder is deleted
  /// after hand-off, so the asset lives in the repo).
  static const String backgroundAsset =
      'assets/images/Gemini_Generated_Image_df2l05df2l05df2l.png';
}

/// Type styles used across the auth flow (kept local so the auth screens
/// don't drag in the light-theme text scale).
abstract final class AuthText {
  static const TextStyle brand = TextStyle(
    fontSize: 40,
    height: 1.1,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    color: AuthColors.textPrimary,
  );

  static const TextStyle title = TextStyle(
    fontSize: 18,
    height: 1.3,
    fontWeight: FontWeight.w600,
    color: AuthColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    height: 1.45,
    color: AuthColors.textPrimary,
  );

  static const TextStyle secondary = TextStyle(
    fontSize: 12.5,
    height: 1.4,
    color: AuthColors.textSecondary,
  );

  static const TextStyle label = TextStyle(
    fontSize: 12,
    height: 1.2,
    fontWeight: FontWeight.w500,
    color: AuthColors.textSecondary,
  );

  static const TextStyle fieldText = TextStyle(
    fontSize: 14,
    height: 1.2,
    color: AuthColors.textPrimary,
  );

  static const TextStyle fieldHint = TextStyle(
    fontSize: 14,
    height: 1.2,
    color: Color(0x8CB7BCC6), // secondary at ~55%
  );

  static const TextStyle errorText = TextStyle(
    fontSize: 12,
    height: 1.3,
    color: AuthColors.error,
  );
}
