/// Central manager for the foreground background service.
///
/// Wraps [FlutterForegroundTask] start/stop calls and handles permission
/// requests for battery optimisation exemption (Android).
library;

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../../background_task.dart' show startBackgroundCallback;
import '../utils/constants.dart';
import '../utils/logger.dart';
import 'notification_service.dart';
import 'workmanager_service.dart';

class BackgroundService {
  BackgroundService._();

  static final BackgroundService instance = BackgroundService._();

  static const String _tag = 'BackgroundService';

  bool _isRunning = false;

  bool get isRunning => _isRunning;

  // ---------------------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------------------

  /// Must be called once during app startup (before [start]).
  Future<void> init() async {
    NotificationService.instance.init();
    await WorkManagerService.instance.init();
    AppLogger.info(_tag, 'BackgroundService initialised');
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Request battery-optimisation exemption then start the foreground service.
  Future<bool> start() async {
    try {
      // Request battery optimisation exemption on Android.
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();

      final result = await FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: AppConstants.notificationTitle,
        notificationText: AppConstants.notificationText,
        callback: startBackgroundCallback,
      );

      if (result == ServiceRequestResult.success) {
        _isRunning = true;
        AppLogger.info(_tag, 'Foreground service started successfully');
        return true;
      } else {
        AppLogger.warning(_tag, 'Foreground service start returned: $result');
        return false;
      }
    } catch (e, st) {
      AppLogger.error(_tag, 'Failed to start foreground service', e, st);
      return false;
    }
  }

  /// Stop the foreground service.
  Future<bool> stop() async {
    try {
      final result = await FlutterForegroundTask.stopService();

      if (result == ServiceRequestResult.success) {
        _isRunning = false;
        AppLogger.info(_tag, 'Foreground service stopped successfully');
        return true;
      } else {
        AppLogger.warning(_tag, 'Foreground service stop returned: $result');
        return false;
      }
    } catch (e, st) {
      AppLogger.error(_tag, 'Failed to stop foreground service', e, st);
      return false;
    }
  }

  /// Check if the service is currently active.
  Future<bool> checkIsRunning() async {
    try {
      _isRunning = await FlutterForegroundTask.isRunningService;
      return _isRunning;
    } catch (e, st) {
      AppLogger.error(_tag, 'checkIsRunning failed', e, st);
      return false;
    }
  }

  /// Attach a listener for data sent from the background isolate.
  ///
  /// Uses [FlutterForegroundTask.addTaskDataCallback] (introduced in v7.x) which
  /// supports multiple listeners and survives app restarts.
  void attachReceivePort(void Function(Object) onData) {
    FlutterForegroundTask.addTaskDataCallback(onData);
  }

  /// Remove a previously attached data listener.
  void detachReceivePort(void Function(Object) onData) {
    FlutterForegroundTask.removeTaskDataCallback(onData);
  }
}
