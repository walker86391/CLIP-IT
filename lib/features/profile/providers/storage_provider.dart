import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/services/notifications_service.dart';
import '../../../core/utils/app_path_resolver.dart';
import '../../messages/providers/messages_provider.dart';

/// State representing local disk storage allocation and measured media usage.
@immutable
class LocalStorageState {
  const LocalStorageState({
    required this.allocatedLimitGb,
    required this.usedBytes,
    required this.isLoading,
    this.lastWarningLimitGb,
  });

  /// The user-configured allocation limit in Gigabytes (5 GB to 30 GB).
  final double allocatedLimitGb;

  /// Total measured media bytes on local disk (clips, audio, models, temp).
  final int usedBytes;

  /// True when a background calculation is in progress.
  final bool isLoading;

  /// Last allocated limit for which a warning was dispatched, to avoid spamming
  /// repeated notifications for the exact same value.
  final double? lastWarningLimitGb;

  /// Used storage in Gigabytes.
  double get usedGb => usedBytes / (1024 * 1024 * 1024);

  /// Usage ratio between 0.0 and 1.0 (or greater if full).
  double get usageRatio =>
      allocatedLimitGb > 0 ? (usedGb / allocatedLimitGb) : 0.0;

  /// Whether current storage usage has reached or exceeded the allocated limit.
  bool get isStorageFull => usedGb >= allocatedLimitGb;

  LocalStorageState copyWith({
    double? allocatedLimitGb,
    int? usedBytes,
    bool? isLoading,
    double? lastWarningLimitGb,
  }) {
    return LocalStorageState(
      allocatedLimitGb: allocatedLimitGb ?? this.allocatedLimitGb,
      usedBytes: usedBytes ?? this.usedBytes,
      isLoading: isLoading ?? this.isLoading,
      lastWarningLimitGb: lastWarningLimitGb ?? this.lastWarningLimitGb,
    );
  }
}

/// Notifier managing local storage allocation and real disk measurement.
class LocalStorageNotifier extends Notifier<LocalStorageState> {
  bool _disposed = false;

  @override
  LocalStorageState build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
    });

    // Default limit is 10.0 GB as specified by user requirements.
    Future.microtask(() {
      if (!_disposed) {
        refreshUsage();
      }
    });

    return const LocalStorageState(
      allocatedLimitGb: 10.0,
      usedBytes: 0,
      isLoading: true,
      lastWarningLimitGb: null,
    );
  }

  /// Recalculates real storage usage by inspecting local ClipIt directories.
  Future<void> refreshUsage() async {
    if (_disposed) return;
    state = state.copyWith(isLoading: true);
    final totalBytes = await _scanClipItMediaUsageBytes();
    if (_disposed) return;

    final usedGb = totalBytes / (1024 * 1024 * 1024);
    final isFull = usedGb >= state.allocatedLimitGb;

    state = state.copyWith(
      usedBytes: totalBytes,
      isLoading: false,
    );

    if (isFull) {
      _dispatchStorageAlert(usedGb, state.allocatedLimitGb);
    }
  }

  /// Updates the allocated local storage limit (clamped between 5 GB and 30 GB).
  ///
  /// If the current usage reaches or exceeds the new limit (e.g. user has ~5.8 GB
  /// and moves the slider to 5 GB), an urgent notification is dispatched to
  /// the Notifications / Messages tab and a warning toast is shown.
  void setAllocatedLimit(double newLimitGb) {
    final clamped = newLimitGb.clamp(5.0, 30.0);
    final usedGb = state.usedGb;
    final isFull = usedGb >= clamped;

    final shouldWarn = isFull && (state.lastWarningLimitGb != clamped);

    state = state.copyWith(
      allocatedLimitGb: clamped,
      lastWarningLimitGb: isFull ? clamped : null,
    );

    if (shouldWarn) {
      _dispatchStorageAlert(usedGb, clamped);
    }
  }

  /// Helper to send notification to the Notifications tab and show an in-app toast.
  void _dispatchStorageAlert(double usedGb, double allocatedGb) {
    // 1. Post notification into Messages / Notification tab
    ref.read(messagesProvider.notifier).addStorageWarning(
      usedGb: usedGb,
      allocatedGb: allocatedGb,
    );

    // 2. Trigger in-app warning toast
    ref.read(notificationsProvider).show(
      NotificationsService.warning(
        'Storage Warning',
        message:
            'Allocated local storage is full (${usedGb.toStringAsFixed(1)} GB / ${allocatedGb.round()} GB used)!',
      ),
    );
  }

  /// Scans directories on disk where ClipIt saves clips, mp3, mp4, audio,
  /// models, and temporary rendering files.
  static Future<int> _scanClipItMediaUsageBytes() async {
    int totalBytes = 0;
    final Set<String> visitedPaths = {};
    final candidateDirs = <String>[];

    // 1. Project root workspace folders & Current directory folders
    final projectDir = AppPathResolver.projectRoot.path;
    candidateDirs.add(p.join(projectDir, 'live process'));
    candidateDirs.add(p.join(projectDir, 'models'));
    candidateDirs.add(p.join(projectDir, 'clips'));
    candidateDirs.add(p.join(projectDir, 'outputs'));
    candidateDirs.add(p.join(projectDir, 'downloads'));
    candidateDirs.add(p.join(projectDir, 'temp'));

    final currentDir = Directory.current.path;
    if (currentDir != projectDir) {
      candidateDirs.add(p.join(currentDir, 'live process'));
      candidateDirs.add(p.join(currentDir, 'models'));
      candidateDirs.add(p.join(currentDir, 'clips'));
      candidateDirs.add(p.join(currentDir, 'outputs'));
      candidateDirs.add(p.join(currentDir, 'downloads'));
      candidateDirs.add(p.join(currentDir, 'temp'));
    }

    // 2. LocalAppData clipit directory (Windows)
    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData != null && localAppData.isNotEmpty) {
      candidateDirs.add(p.join(localAppData, 'clipit'));
    }

    // 3. User Downloads ClipIt_Downloads directory
    final userProfile = Platform.environment['USERPROFILE'] ??
        Platform.environment['HOME'];
    if (userProfile != null && userProfile.isNotEmpty) {
      candidateDirs.add(p.join(userProfile, 'Downloads', 'ClipIt_Downloads'));
    }

    // 4. Application support directories
    try {
      final appSupport = await getApplicationSupportDirectory();
      candidateDirs.add(p.join(appSupport.path, 'ClipItV1'));
      candidateDirs.add(p.join(appSupport.path, 'clips'));
      candidateDirs.add(p.join(appSupport.path, 'temp'));
      candidateDirs.add(p.join(appSupport.path, 'models'));
    } catch (_) {}

    // Iterate through candidates and aggregate file sizes
    for (final dirPath in candidateDirs) {
      final dir = Directory(dirPath);
      if (dir.existsSync()) {
        try {
          final entities = dir.listSync(recursive: true, followLinks: false);
          for (final entity in entities) {
            if (entity is File && visitedPaths.add(entity.path)) {
              try {
                totalBytes += entity.lengthSync();
              } catch (_) {}
            }
          }
        } catch (_) {}
      }
    }

    return totalBytes;
  }
}

/// Provider for Local Storage allocation and measurement.
final localStorageProvider =
    NotifierProvider<LocalStorageNotifier, LocalStorageState>(
  LocalStorageNotifier.new,
);
