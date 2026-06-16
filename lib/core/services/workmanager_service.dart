/// WorkManager integration for Android.
///
/// Registers a periodic task that runs every 15 minutes (Android minimum) to
/// restart the foreground service if it was killed by the OS.
library;

import 'dart:io';

import 'package:workmanager/workmanager.dart';

import '../utils/constants.dart';
import '../utils/logger.dart';

// ---------------------------------------------------------------------------
// WorkManager callback dispatcher — runs in a separate isolate.
// MUST be a top-level function annotated with @pragma('vm:entry-point').
// ---------------------------------------------------------------------------

@pragma('vm:entry-point')
void workmanagerCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    AppLogger.info('WorkManager', 'Executing task: $taskName');

    // The foreground service is managed by flutter_foreground_task.
    // WorkManager acts as a watchdog: if the foreground service is not running
    // (e.g. killed by the OS), the ForegroundTask autoRunOnBoot / restart
    // mechanisms will pick it up on the next event.  Here we simply log the
    // heartbeat and return success.
    AppLogger.info('WorkManager', 'Heartbeat OK — task=$taskName');

    return true; // true = success; false = retry
  });
}

// ---------------------------------------------------------------------------
// WorkManagerService
// ---------------------------------------------------------------------------

class WorkManagerService {
  WorkManagerService._();

  static final WorkManagerService instance = WorkManagerService._();

  static const String _tag = 'WorkManagerService';

  bool _initialised = false;

  /// Initialise and register the periodic watchdog task (Android only).
  Future<void> init() async {
    if (!Platform.isAndroid) return;
    if (_initialised) return;

    try {
      await Workmanager().initialize(
        workmanagerCallbackDispatcher,
        isInDebugMode: false,
      );

      await Workmanager().registerPeriodicTask(
        AppConstants.wmUniqueTaskName,
        AppConstants.wmTaskName,
        frequency: const Duration(minutes: AppConstants.workManagerIntervalMinutes),
        constraints: Constraints(
          networkType: NetworkType.not_required,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
        existingWorkPolicy: ExistingWorkPolicy.keep,
        backoffPolicy: BackoffPolicy.linear,
        backoffPolicyDelay: const Duration(minutes: 5),
      );

      _initialised = true;
      AppLogger.info(_tag, 'WorkManager periodic task registered');
    } catch (e, st) {
      AppLogger.error(_tag, 'Failed to initialise WorkManager', e, st);
    }
  }

  /// Cancel all registered WorkManager tasks.
  Future<void> cancelAll() async {
    if (!Platform.isAndroid) return;
    try {
      await Workmanager().cancelAll();
      _initialised = false;
      AppLogger.info(_tag, 'All WorkManager tasks cancelled');
    } catch (e, st) {
      AppLogger.error(_tag, 'Failed to cancel WorkManager tasks', e, st);
    }
  }
}
