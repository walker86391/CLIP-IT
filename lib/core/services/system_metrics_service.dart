import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

bool get _isTestRunning {
  try {
    final binding = WidgetsBinding.instance;
    final typeName = binding.runtimeType.toString();
    if (typeName.contains('Test')) return true;
  } catch (_) {}
  return Platform.environment.containsKey('FLUTTER_TEST');
}

/// Machine diagnostic snapshot retrieved once at app launch.
class SystemMetrics {
  const SystemMetrics({
    this.cpuPercent = '0.0%',
    this.gpuPercent = '0.0%',
    this.ramPercent = '0.0%',
  });

  final String cpuPercent;
  final String gpuPercent;
  final String ramPercent;

  String get displayText => 'CPU: $cpuPercent  GPU: $gpuPercent  RAM: $ramPercent';
}

final class SystemMetricsNotifier extends Notifier<SystemMetrics> {
  bool _fetched = false;

  @override
  SystemMetrics build() {
    return const SystemMetrics();
  }

  /// Fetches system metrics once asynchronously without stalling the UI thread.
  Future<void> fetchOnce() async {
    if (_fetched) return;
    _fetched = true;

    if (!Platform.isWindows || _isTestRunning) {
      return;
    }

    try {
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-Command',
        r'''
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        $usedRam = if ($os) { [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100) } else { 0 }
        $cpu = (Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Measure-Object -Property LoadPercentage -Average).Average
        if ($null -eq $cpu) { $cpu = 0 } else { $cpu = [math]::Round($cpu) }
        $gpuCounter = (Get-Counter "\GPU Engine(*engtype_3D)\Utilization Percentage" -ErrorAction SilentlyContinue).CounterSamples | Measure-Object -Property CookedValue -Sum
        $gpu = if ($gpuCounter) { [math]::Round($gpuCounter.Sum) } else { 0 }
        Write-Output "$cpu,$usedRam,$gpu"
        '''
      ]).timeout(const Duration(seconds: 4));

      if (result.exitCode == 0) {
        final line = result.stdout.toString().trim();
        final parts = line.split(',');
        if (parts.length >= 3) {
          final cpu = int.tryParse(parts[0].trim()) ?? 0;
          final ram = int.tryParse(parts[1].trim()) ?? 0;
          final gpu = int.tryParse(parts[2].trim()) ?? 0;
          state = SystemMetrics(
            cpuPercent: '$cpu.0%',
            gpuPercent: '$gpu.0%',
            ramPercent: '$ram.0%',
          );
        }
      }
    } catch (_) {
      // Graceful fallback to default values on error or timeout
    }
  }
}

final systemMetricsProvider =
    NotifierProvider<SystemMetricsNotifier, SystemMetrics>(
  SystemMetricsNotifier.new,
);
