import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/system_metrics_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../ui/tokens/motion.dart';
import '../auth_theme.dart';
import '../providers/auth_provider.dart';

/// /loading — brand moment + auth init gate.
///
/// Dark gray background, centered "ClipIt" wordmark, shimmer progress bar.
/// When auth init resolves we give the branding a beat (~900 ms minimum
/// display) and then navigate: authenticated → /ok, otherwise → /auth.
/// The reveal itself is the blur entrance transition on the /auth route
/// (see router.dart).
class LoadingPage extends ConsumerStatefulWidget {
  const LoadingPage({super.key});

  @override
  ConsumerState<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends ConsumerState<LoadingPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(systemMetricsProvider.notifier).fetchOnce();
    });
    _scheduleNavigation();
  }

  Future<void> _scheduleNavigation() async {
    try {
      // Wait for auth init (stub resolves immediately; Supabase may take
      // a network round trip).
      final authState = await ref.read(authReadyProvider.future);
      if (!mounted) return;

      final target = authState.status == AuthStatus.authenticated
          ? Routes.home
          : Routes.auth;

      // Minimum branding display time so the load never "flashes".
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;

      context.go(target);
    } catch (e) {
      AppLog.e('Auth ready failed while loading — falling back to /auth', e);
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      context.go(Routes.auth);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = AppMotion.disabled(context);

    return Scaffold(
      backgroundColor: AuthColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Brand wordmark.
            const Text('ClipIt', style: AuthText.brand),
            const SizedBox(height: 28),
            // Progress bar with gentle shimmer.
            _ShimmerProgressBar(reduceMotion: reduceMotion),
          ],
        ),
      ),
    );
  }
}

/// Thin 240×4 progress bar with a soft moving highlight.
class _ShimmerProgressBar extends StatefulWidget {
  const _ShimmerProgressBar({required this.reduceMotion});

  final bool reduceMotion;

  @override
  State<_ShimmerProgressBar> createState() => _ShimmerProgressBarState();
}

class _ShimmerProgressBarState extends State<_ShimmerProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const double _trackWidth = 240;
  static const double _trackHeight = 4;
  static const double _highlightWidth = 110;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (!widget.reduceMotion) {
      _controller.repeat();
    } else {
      // Reduced motion: gentle single-pulse opacity instead of sweep.
      _controller.value = 0.5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final track = Container(
      width: _trackWidth,
      height: _trackHeight,
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF), // white ~8%
        borderRadius: BorderRadius.circular(2),
      ),
    );

    if (widget.reduceMotion) {
      // Static accent fill at reduced strength.
      return Stack(
        alignment: Alignment.centerLeft,
        children: [
          track,
          FractionallySizedBox(
            widthFactor: 0.45,
            child: Container(
              height: _trackHeight,
              decoration: BoxDecoration(
                color: AuthColors.accent.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        width: _trackWidth,
        height: _trackHeight,
        child: Stack(
          children: [
            // Track.
            Positioned.fill(child: track),
            // Moving gradient highlight.
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final travel = _trackWidth + _highlightWidth;
                final offset =
                    Curves.easeInOut.transform(_controller.value) * travel -
                        _highlightWidth;
                return Positioned(
                  left: offset,
                  top: 0,
                  bottom: 0,
                  width: _highlightWidth,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AuthColors.accent.withValues(alpha: 0.0),
                          AuthColors.accent.withValues(alpha: 0.9),
                          AuthColors.accent.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
