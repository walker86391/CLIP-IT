import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// Desktop toolbar: title on the left, trailing actions on the right.
///
/// Used inside the shell's top bar and by feature pages that need a
/// secondary action row.
class AppToolbar extends StatelessWidget {
  const AppToolbar({
    required this.title,
    this.actions = const [],
    this.leading,
    this.trailing,
    super.key,
  });

  final String title;
  final List<Widget> actions;

  /// Widget before the title (e.g. back button, breadcrumb).
  final Widget? leading;

  /// Extra trailing widget after [actions] (e.g. a persistent indicator).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.toolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: Spacing.md)],
          Text(
            title,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: AppTypography.wSemibold,
            ),
          ),
          const Spacer(),
          ...actions,
          if (trailing != null) ...[
            const SizedBox(width: Spacing.md),
            trailing!,
          ],
        ],
      ),
    );
  }
}
