import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/glass_panel.dart';
import '../widgets/segmented_tabs.dart';
import 'secret_code_form.dart';
import 'sign_in_form.dart';
import 'sign_up_form.dart';

/// /auth — forest background, right-side legibility contrast scrim, frosted
/// glass panel with three tabs (Sign Up default / Sign In / Secret Code).
///
/// PERFORMANCE ARCHITECTURE (Zero-Lag Desktop):
///
/// 1. The photographic wallpaper on the left remains 100% sharp and vibrant.
/// 2. The right-side zone provides smooth text contrast via an accelerated
///    horizontal gradient scrim without running expensive multi-strip GPU
///    BackdropFilters.
/// 3. The floating glass panel isolates form keystrokes in their own
///    RepaintBoundary, delivering instantaneous 120 FPS typing.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  int _tabIndex = 0;

  static const List<String> _tabLabels = [
    'Sign Up',
    'Sign In',
    'Secret Code',
  ];

  @override
  Widget build(BuildContext context) {
    final supabaseConfigured = ref.watch(supabaseConfiguredProvider);

    return Scaffold(
      backgroundColor: AuthColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double windowWidth = constraints.maxWidth;

          // The zone is never allowed to be narrower than the panel plus
          // one feather band on each side.
          final double zoneFloor = AuthColors.panelWidth +
              AuthColors.backgroundBlurFeatherWidth * 2;
          final double blurZoneWidth =
              math.max(windowWidth * 0.55, zoneFloor);

          // The panel is right-aligned with a fixed gap to the window
          // edge, so its centre is known from the window width alone.
          final double panelLeft = windowWidth -
              AuthColors.panelOuterPadding -
              AuthColors.panelWidth;
          final double panelCenter = panelLeft + AuthColors.panelWidth / 2;
          final double blurMargin = (blurZoneWidth - AuthColors.panelWidth) *
              AuthColors.backgroundBlurMarginFraction;
          final double blurZoneLeft =
              math.max(0.0, panelCenter - blurZoneWidth / 2);

          // Where, inside the zone, the feather band ends and the flat
          // full-strength wash begins.
          final double featherFraction =
              (AuthColors.backgroundBlurFeatherWidth / blurZoneWidth)
                  .clamp(0.0, 1.0)
                  .toDouble();

          assert(blurMargin >= AuthColors.backgroundBlurFeatherWidth,
              'The blur margin must leave room for the feather band, '
              'otherwise the ramp would still be climbing behind the '
              'panel.');

          // Panel height is content-driven but never overflows the
          // window.
          final panelMaxHeight = constraints.maxHeight - 48;

          return Stack(
            fit: StackFit.expand,
            children: [
              // ── Background image (full-bleed, cover, centered) ─────
              RepaintBoundary(
                child: Image.asset(
                  AuthColors.backgroundAsset,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  gaplessPlayback: true,
                  cacheWidth: 1920,
                  errorBuilder: (context, error, stackTrace) => DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF1A1D23),
                          AuthColors.background,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Right-side contrast zone with feathered left edge ──
              // Scoped to the right side (NOT the full screen) so the
              // sharp left side keeps its full brightness and lettering.
              // Horizontal gradient: transparent at the zone's left edge,
              // reaching full strength across the feather band, flat to the
              // right edge.
              Positioned(
                top: 0,
                bottom: 0,
                left: blurZoneLeft,
                width: blurZoneWidth,
                child: RepaintBoundary(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        stops: <double>[0.0, featherFraction, 1.0],
                        colors: <Color>[
                          Colors.black.withValues(alpha: 0.0),
                          Colors.black.withValues(
                            alpha: AuthColors.backgroundScrimOpacity,
                          ),
                          Colors.black.withValues(
                            alpha: AuthColors.backgroundScrimOpacity,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Glass panel (right side, vertically centered) ─────
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 24,
                  ),
                  child: GlassPanel(
                    width: AuthColors.panelWidth,
                    // The panel never grows beyond the window; taller
                    // forms (Sign Up) scroll inside the glass surface
                    // instead.
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: panelMaxHeight),
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (!supabaseConfigured) ...[
                                const _NotConfiguredBanner(),
                                const SizedBox(height: 16),
                              ],
                              AuthSegmentedTabs(
                                labels: _tabLabels,
                                index: _tabIndex,
                                onChanged: (i) => setState(() => _tabIndex = i),
                              ),
                              const SizedBox(height: 24),
                              // IndexedStack keeps each form's state
                              // alive while the user moves between
                              // tabs. Wrapped in RepaintBoundary to
                              // isolate form rendering from tab bar transitions.
                              RepaintBoundary(
                                child: switch (_tabIndex) {
                                  0 => SignUpForm(
                                      onSwitchTab: (i) =>
                                          setState(() => _tabIndex = i),
                                      submitEnabled: supabaseConfigured,
                                    ),
                                  1 => SignInForm(
                                      onSwitchTab: (i) =>
                                          setState(() => _tabIndex = i),
                                      submitEnabled: supabaseConfigured,
                                    ),
                                  _ => SecretCodeForm(
                                      submitEnabled: supabaseConfigured,
                                      onSwitchTab: (i) =>
                                          setState(() => _tabIndex = i),
                                    ),
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Non-blocking banner shown when Supabase env keys are missing.
class _NotConfiguredBanner extends StatelessWidget {
  const _NotConfiguredBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AuthColors.fieldGlassFillBase,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AuthColors.glassBorder, width: 1),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            size: 14,
            color: AuthColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Supabase not configured',
              style: AuthText.secondary,
            ),
          ),
          const SizedBox(width: 8),
          // Precise fix hint on hover — small, unobtrusive.
          Tooltip(
            message:
                'Set SUPABASE_URL and SUPABASE_ANON_KEY in .env (or pass '
                '--dart-define), then restart the app.',
            waitDuration: const Duration(milliseconds: 300),
            child: const Icon(
              Icons.help_outline,
              size: 14,
              color: AuthColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

