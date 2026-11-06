/// Hardware/resource detection boundary.
///
/// Step 0: stub. Real detection (CPU cores, GPU, RAM) comes later and will
/// gate engine settings (threads, model size, etc.).
abstract class ResourceManager {
  Future<void> init();

  /// Snapshot of machine resources. Returns nulls until implemented.
  Future<ResourceSnapshot> snapshot();
}

class ResourceSnapshot {
  const ResourceSnapshot({
    this.cpuCores,
    this.totalMemoryBytes,
    this.gpuName,
  });

  final int? cpuCores;
  final int? totalMemoryBytes;
  final String? gpuName;
}
