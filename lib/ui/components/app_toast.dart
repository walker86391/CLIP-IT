import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../core/services/notifications_service.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// Toast overlay: listens to NotificationsService and displays queued
/// toasts bottom-right (desktop convention).
///
/// Wrap the app above the Navigator with this builder.
class AppToastOverlay extends ConsumerStatefulWidget {
  const AppToastOverlay({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppToastOverlay> createState() => _AppToastOverlayState();
}

class _AppToastOverlayState extends ConsumerState<AppToastOverlay> {
  StreamSubscription<AppNotification>? _sub;
  final List<_ToastEntry> _toasts = [];

  @override
  void initState() {
    super.initState();
    _sub = ref.read(notificationsProvider).stream.listen(_onNotification);
  }

  void _onNotification(AppNotification n) {
    if (!mounted) return;
    final entry = _ToastEntry(notification: n);
    setState(() => _toasts.add(entry));
    Timer(n.duration, () {
      if (mounted) setState(() => _toasts.remove(entry));
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          right: Spacing.lg,
          bottom: Spacing.lg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final entry in _toasts)
                Padding(
                  padding: const EdgeInsets.only(top: Spacing.sm),
                  child: _ToastCard(
                    key: ValueKey(entry.notification.id),
                    notification: entry.notification,
                    onDismiss: () => setState(() => _toasts.remove(entry)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ToastEntry {
  _ToastEntry({required this.notification});
  final AppNotification notification;
}

class _ToastCard extends StatefulWidget {
  const _ToastCard({
    required this.notification,
    required this.onDismiss,
    super.key,
  });

  final AppNotification notification;
  final VoidCallback onDismiss;

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard> {
  bool _hovered = false;

  Color get _accent => switch (widget.notification.level) {
        NotificationLevel.info => AppColors.accent,
        NotificationLevel.success => AppColors.success,
        NotificationLevel.warning => AppColors.warning,
        NotificationLevel.error => AppColors.danger,
      };

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 320,
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.rMd,
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(color: Color(0x1F000000), blurRadius: 16, offset: Offset(0, 6)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 3,
              height: 34,
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.title,
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (n.message != null)
                    Text(
                      n.message!,
                      style: AppTypography.secondary
                          .copyWith(color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            AnimatedOpacity(
              opacity: _hovered ? 1 : 0,
              duration: const Duration(milliseconds: 120),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: widget.onDismiss,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
