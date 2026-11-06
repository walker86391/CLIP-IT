import '../models/feature_flag.dart';

/// Feature flag boundary.
///
/// Step 0: local in-memory defaults. Later: local JSON file, then remote.
abstract class FeatureFlagsService {
  bool isEnabled(String key);

  /// All flags with metadata (for a future debug panel).
  Map<String, FeatureFlag> get all;

  void setOverride(String key, {required bool enabled});
}

/// In-memory implementation with sensible defaults.
final class FeatureFlagsServiceImpl implements FeatureFlagsService {
  final Map<String, FeatureFlag> _flags = {
    'reduce_motion_defaults': const FeatureFlag(
      key: 'reduce_motion_defaults',
      enabled: false,
      description: 'Default reduceMotion for new installs.',
    ),
    'simulated_pipeline': const FeatureFlag(
      key: 'simulated_pipeline',
      enabled: true,
      description: 'Use JobServiceMock instead of a real engine.',
    ),
  };

  final Map<String, bool> _overrides = {};

  @override
  bool isEnabled(String key) =>
      _overrides[key] ?? _flags[key]?.enabled ?? false;

  @override
  Map<String, FeatureFlag> get all => Map.unmodifiable(_flags);

  @override
  void setOverride(String key, {required bool enabled}) {
    _overrides[key] = enabled;
  }
}
