import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bus/action_bus.dart';
import '../db/app_database.dart';
import '../models/job.dart';
import '../models/settings.dart';
import '../repos/job_repo.dart';
import '../repos/project_repo.dart';
import '../repos/settings_repo.dart';
import '../services/feature_flags_service.dart';
import '../services/job_service.dart';
import '../services/job_service_mock.dart';
import '../services/notifications_service.dart';
import '../services/remote_config_service.dart';
import '../utils/app_logger.dart';

// ── Infrastructure ────────────────────────────────────────────────────────

/// Opened lazily on first access; kept alive for the app session.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// ── Repos ─────────────────────────────────────────────────────────────────

final jobRepoProvider = Provider<JobRepo>(
  (ref) => JobRepo(ref.watch(appDatabaseProvider)),
);

final projectRepoProvider = Provider<ProjectRepo>(
  (ref) => ProjectRepo(ref.watch(appDatabaseProvider)),
);

final settingsRepoProvider = Provider<SettingsRepo>(
  (ref) => SettingsRepo(ref.watch(appDatabaseProvider)),
);

// ── Bus ───────────────────────────────────────────────────────────────────

/// Typed command/event bus. UI dispatches; services act.
final actionBusProvider = Provider<ActionBus>((ref) {
  final bus = ActionBus();
  ref.onDispose(bus.dispose);
  return bus;
});

// ── Services ──────────────────────────────────────────────────────────────

/// JobService (mock in Step 0). Started once; listens for bus commands.
final jobServiceProvider = Provider<JobService>((ref) {
  final service = JobServiceMock(ref.watch(jobRepoProvider));
  service.start(ref.watch(actionBusProvider));
  ref.onDispose(service.dispose);
  return service;
});

final notificationsProvider = Provider<NotificationsService>((ref) {
  final service = NotificationsServiceImpl();
  ref.onDispose(service.dispose);
  return service;
});

final featureFlagsProvider = Provider<FeatureFlagsService>(
  (ref) => FeatureFlagsServiceImpl(),
);

/// Remote config stub — no implementation in Step 0; call sites compile
/// against the interface.
final remoteConfigProvider = Provider<RemoteConfigService>(
  (ref) => throw UnimplementedError(
    'RemoteConfigService not configured in Step 0. '
    'TODO: implement with Supabase.',
  ),
);

// ── Job manager facade ────────────────────────────────────────────────────

/// Facade over JobService + JobRepo. UI reads jobs here and dispatches
/// commands through the bus — never touching repos or services directly.
final class JobManager {
  JobManager({required this.bus, required this.service, required this.repo});

  final ActionBus bus;
  final JobService service;
  final JobRepo repo;

  void createJob(JobCreateCommand command) =>
      bus.dispatch(CreateJob(command));

  void cancelJob(String jobId) => bus.dispatch(CancelJob(jobId));

  void retryJob(String jobId) => bus.dispatch(RetryJob(jobId));

  /// Reactive list of recent jobs for UI.
  Stream<List<Job>> watchRecent({int limit = 50}) =>
      repo.watchRecent(limit: limit);

  /// Live event stream from the job layer.
  Stream<JobEvent> get events => bus.eventStream;
}

final jobManagerProvider = Provider<JobManager>((ref) {
  return JobManager(
    bus: ref.watch(actionBusProvider),
    service: ref.watch(jobServiceProvider),
    repo: ref.watch(jobRepoProvider),
  );
});

/// Stream of recent jobs (most recent first).
final recentJobsProvider = StreamProvider<List<Job>>((ref) {
  return ref.watch(jobManagerProvider).watchRecent();
});

// ── Settings ──────────────────────────────────────────────────────────────

/// In-memory settings state; mutated via [settingsControllerProvider].
final class AppSettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => const AppSettings();

  void set(AppSettings settings) => state = settings;
}

final appSettingsProvider =
    NotifierProvider<AppSettingsNotifier, AppSettings>(
      AppSettingsNotifier.new,
    );

/// Persists settings changes and updates the in-memory state.
final settingsControllerProvider = Provider<SettingsController>((ref) {
  return SettingsController(ref);
});

final class SettingsController {
  SettingsController(this._ref);

  final Ref _ref;

  AppSettings get current => _ref.read(appSettingsProvider);

  Future<void> update(AppSettings settings) async {
    _ref.read(appSettingsProvider.notifier).set(settings);
    try {
      await _ref.read(settingsRepoProvider).write(settings);
    } catch (e, s) {
      AppLog.e('Failed to persist settings', e, s);
    }
  }

  Future<void> setReduceMotion(bool value) =>
      update(current.copyWith(reduceMotion: value));

  Future<void> setThemeMode(AppThemeMode mode) =>
      update(current.copyWith(themeMode: mode));
}

/// Shell active navigation index (0 = Home, 8 = Settings)
final class ShellNavigationIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) => state = index;
}

final shellNavigationIndexProvider =
    NotifierProvider<ShellNavigationIndexNotifier, int>(
      ShellNavigationIndexNotifier.new,
    );

/// Active category tab index in SettingsPage (2 = Downloader & Cookies)
final class SettingsCategoryIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) => state = index;
}

final settingsCategoryIndexProvider =
    NotifierProvider<SettingsCategoryIndexNotifier, int>(
      SettingsCategoryIndexNotifier.new,
    );

/// Global search query entered in the AppTopBar
final class GlobalSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
  void clear() => state = '';
}

final globalSearchQueryProvider =
    NotifierProvider<GlobalSearchQueryNotifier, String>(
      GlobalSearchQueryNotifier.new,
    );
