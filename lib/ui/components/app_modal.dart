import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';
import 'app_button.dart';

/// ClipIt modal dialog: consistent surface, title, message, actions.
///
/// Shows via showDialog; returns a `Future<bool?>`-style result from actions.
class AppModal {
  AppModal._();

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    String? message,
    List<Widget> actions = const [],
    Widget? content,
    bool dismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: dismissible,
      builder: (context) => _AppModalShell(
        title: title,
        message: message,
        actions: actions,
        content: content,
      ),
    );
  }

  /// Convenience confirm dialog → true/false.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    String? message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _AppModalShell(
        title: title,
        message: message,
        actions: [
          AppButton(
            label: cancelLabel,
            variant: AppButtonVariant.ghost,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          AppButton(
            label: confirmLabel,
            variant: destructive
                ? AppButtonVariant.danger
                : AppButtonVariant.primary,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _AppModalShell extends StatelessWidget {
  const _AppModalShell({
    required this.title,
    this.message,
    this.actions = const [],
    this.content,
  });

  final String title;
  final String? message;
  final List<Widget> actions;
  final Widget? content;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(Spacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.rLg,
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(color: Color(0x29000000), blurRadius: 32, offset: Offset(0, 12)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.sectionTitle.copyWith(color: AppColors.textPrimary),
            ),
            if (message != null) ...[
              const SizedBox(height: Spacing.sm),
              Text(
                message!,
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              ),
            ],
            if (content != null) ...[
              const SizedBox(height: Spacing.lg),
              content!,
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: Spacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  for (final (i, action) in actions.indexed) ...[
                    if (i > 0) const SizedBox(width: Spacing.sm),
                    action,
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
