/// GetX controller for the dashboard screen.
///
/// Bridges the background isolate data (received via [BackgroundService])
/// with the reactive UI by keeping observable state variables up to date.
library;

import 'package:get/get.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/models/task_log.dart';
import '../../../core/services/background_service.dart';
import '../../../core/utils/logger.dart';

class DashboardController extends GetxController {
  static const String _tag = 'DashboardController';

  // ---------------------------------------------------------------------------
  // Observable state
  // ---------------------------------------------------------------------------

  final RxBool isServiceRunning = false.obs;
  final RxInt executionCount = 0.obs;
  final RxInt successCount = 0.obs;
  final RxInt failureCount = 0.obs;
  final Rx<DateTime?> lastExecutionTime = Rx<DateTime?>(null);
  final RxList<TaskLog> recentLogs = <TaskLog>[].obs;
  final RxBool isLoading = false.obs;
  final RxString statusMessage = ''.obs;

  double get successRate {
    if (executionCount.value == 0) return 0.0;
    return (successCount.value / executionCount.value) * 100;
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    _initialise();
  }

  @override
  void onClose() {
    BackgroundService.instance.detachReceivePort(_onBackgroundData);
    super.onClose();
  }

  Future<void> _initialise() async {
    isLoading.value = true;
    try {
      await BackgroundService.instance.init();
      final running = await BackgroundService.instance.checkIsRunning();
      isServiceRunning.value = running;
      await _loadStats();
      _listenToBackground();
      AppLogger.info(_tag, 'Initialised — service running: $running');
    } catch (e, st) {
      AppLogger.error(_tag, 'Initialisation error', e, st);
      statusMessage.value = 'Initialisation error: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Background data listener
  // ---------------------------------------------------------------------------

  void _listenToBackground() {
    BackgroundService.instance.attachReceivePort(_onBackgroundData);
  }

  Future<void> _onBackgroundData(Object data) async {
    if (data is! Map) return;
    final ts = data['timestamp'] as String?;
    final success = data['success'] as bool? ?? false;
    final error = data['error'] as String?;
    final durationMs = data['durationMs'] as int? ?? 0;

    AppLogger.info(_tag, 'Received from BG: $data');

    // Persist to database.
    final log = TaskLog(
      timestamp: ts != null ? DateTime.parse(ts) : DateTime.now(),
      status: success ? TaskStatus.success : TaskStatus.failure,
      errorMessage: error,
      executionDurationMs: durationMs,
    );
    await AppDatabase.instance.insertLog(log);

    // Prune old logs periodically.
    if ((data['count'] as int? ?? 0) % 20 == 0) {
      await AppDatabase.instance.pruneOldLogs();
    }

    // Update observables.
    executionCount.value = data['count'] as int? ?? executionCount.value + 1;
    if (ts != null) lastExecutionTime.value = DateTime.parse(ts);
    if (success) {
      successCount.value++;
    } else {
      failureCount.value++;
    }

    // Reload the log list for the UI.
    await _reloadLogs();
  }

  // ---------------------------------------------------------------------------
  // Service control
  // ---------------------------------------------------------------------------

  Future<void> startService() async {
    isLoading.value = true;
    statusMessage.value = '';
    try {
      final ok = await BackgroundService.instance.start();
      isServiceRunning.value = ok;
      statusMessage.value = ok ? 'Service started.' : 'Failed to start service.';
      AppLogger.info(_tag, 'startService result: $ok');
    } catch (e, st) {
      AppLogger.error(_tag, 'startService error', e, st);
      statusMessage.value = 'Error starting service: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> stopService() async {
    isLoading.value = true;
    statusMessage.value = '';
    try {
      final ok = await BackgroundService.instance.stop();
      if (ok) isServiceRunning.value = false;
      statusMessage.value = ok ? 'Service stopped.' : 'Failed to stop service.';
      AppLogger.info(_tag, 'stopService result: $ok');
    } catch (e, st) {
      AppLogger.error(_tag, 'stopService error', e, st);
      statusMessage.value = 'Error stopping service: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Database helpers
  // ---------------------------------------------------------------------------

  Future<void> _loadStats() async {
    executionCount.value = await AppDatabase.instance.getTotalCount();
    successCount.value = await AppDatabase.instance.getSuccessCount();
    failureCount.value = await AppDatabase.instance.getFailureCount();
    await _reloadLogs();
  }

  Future<void> _reloadLogs() async {
    final logs = await AppDatabase.instance.getRecentLogs();
    recentLogs.assignAll(logs);
  }

  Future<void> clearLogs() async {
    await AppDatabase.instance.clearAllLogs();
    executionCount.value = 0;
    successCount.value = 0;
    failureCount.value = 0;
    recentLogs.clear();
    statusMessage.value = 'Logs cleared.';
  }

  Future<void> refreshStats() async {
    await _loadStats();
  }
}
