import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/core_providers.dart';
import '../providers/storage_provider.dart';

/// Professional Account & Profile Settings Screen for ClipIt.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageState = ref.watch(localStorageProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1016),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'ACCOUNT & PROFILE',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: Color(0xFFF3F4F8),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Manage your user profile, subscription plan, connected accounts, and local storage allocation.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8E92A6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Profile Card
            _Card(
              title: 'PROFILE DETAILS',
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF8B5CF6),
                    ),
                    child: const Center(
                      child: Text(
                        'S',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Shivam C.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFF3F4F8),
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'shivam@example.com  •  @shivamc',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8E92A6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E202C),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFF2C2F42),
                        width: 1.0,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE2E4ED),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Subscription Card
            _Card(
              title: 'SUBSCRIPTION & BILLING',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Free Plan (Active)',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            r'$0 / month',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFD1D5E5),
                            ),
                          ),
                        ],
                      ),
                      // Upgrade to PRO+ Button (Redirects to Home Page)
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            ref
                                .read(shellNavigationIndexProvider.notifier)
                                .setIndex(0);
                            try {
                              context.go('/home');
                            } catch (_) {}
                          },
                          child: Container(
                            height: 34,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF8B5CF6)
                                      .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.star_rounded,
                                  size: 15,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Upgrade to PRO+',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'You have unlimited free clips with ads and basic export resolution. Upgrade to PRO+ for 4K exports, zero ads, and multi-speaker AI tracking.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF7E8299),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Usage & Storage Card
            _Card(
              title: 'STORAGE & USAGE',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row: Local Storage & Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.folder_special_outlined,
                            size: 17,
                            color: Color(0xFF8B5CF6),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Local Storage',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF3F4F8),
                            ),
                          ),
                          if (storageState.isLoading) ...[
                            const SizedBox(width: 8),
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.8,
                                color: Color(0xFF8B5CF6),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            '${storageState.usedGb.toStringAsFixed(2)} GB / ${storageState.allocatedLimitGb.round()} GB used (${(storageState.usageRatio * 100).toStringAsFixed(0)}%)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: storageState.isStorageFull
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF8E92A6),
                            ),
                          ),
                          if (storageState.isStorageFull) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444)
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'FULL',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => ref
                                  .read(localStorageProvider.notifier)
                                  .refreshUsage(),
                              child: const Tooltip(
                                message: 'Recalculate local storage',
                                child: Icon(
                                  Icons.refresh_rounded,
                                  size: 16,
                                  color: Color(0xFF7E8299),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Storage Progress Indicator Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: storageState.usageRatio.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: const Color(0xFF1E202C),
                      valueColor: AlwaysStoppedAnimation(
                        storageState.isStorageFull
                            ? const Color(0xFFEF4444)
                            : (storageState.usageRatio >= 0.8
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFF8B5CF6)),
                      ),
                    ),
                  ),

                  // Warning alert box if storage is full
                  if (storageState.isStorageFull) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_rounded,
                            size: 18,
                            color: Color(0xFFEF4444),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Allocated storage limit reached (${storageState.usedGb.toStringAsFixed(2)} GB used of ${storageState.allocatedLimitGb.round()} GB). A warning has been sent to your Notifications tab. Drag the slider below to allocate more storage or delete unneeded clips.',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFFFCA5A5),
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Allocate Local Storage Slider Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF12131C),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF222432),
                        width: 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(
                                  Icons.tune_rounded,
                                  size: 16,
                                  color: Color(0xFFD1D5E5),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Allocate Local Storage',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFF3F4F8),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFF8B5CF6)
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                '${storageState.allocatedLimitGb.round()} GB Limit',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFC4B5FD),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Configure the maximum local storage limit allocated for clips, audio extractions (.wav, .mp3), and video exports. Minimum 5 GB, Maximum 30 GB (Default: 10 GB).',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF7E8299),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Interactive Storage Slider
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: const Color(0xFF8B5CF6),
                            inactiveTrackColor: const Color(0xFF262838),
                            thumbColor: const Color(0xFFA78BFA),
                            overlayColor:
                                const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8,
                            ),
                          ),
                          child: Slider(
                            value: storageState.allocatedLimitGb,
                            min: 5.0,
                            max: 30.0,
                            divisions: 25,
                            label: '${storageState.allocatedLimitGb.round()} GB',
                            onChanged: (newValue) {
                              ref
                                  .read(localStorageProvider.notifier)
                                  .setAllocatedLimit(newValue);
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                '5 GB (Min)',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: Color(0xFF6B6E82),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '10 GB (Default)',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: Color(0xFF8B5CF6),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '30 GB (Max)',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: Color(0xFF6B6E82),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF161722),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF262838),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: Color(0xFF7E8299),
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
