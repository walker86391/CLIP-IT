import 'package:flutter/material.dart';

import '../tokens/colors.dart';

/// Thin determinate/indeterminate progress bar.
///
/// Desktop-appropriate: 3px track, no chunky Material indicator.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({this.value, super.key});

  /// 0.0–1.0, or null for indeterminate.
  final double? value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: 3,
        child: LinearProgressIndicator(
          value: value,
          backgroundColor: AppColors.border,
          valueColor: const AlwaysStoppedAnimation(AppColors.accent),
          minHeight: 3,
        ),
      ),
    );
  }
}
