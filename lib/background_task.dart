/// Background isolate entry-point and task handler.
///
/// This file runs in a **separate Dart isolate** managed by
/// flutter_foreground_task. It has no access to the Flutter UI context.
///
/// [startBackgroundCallback] is the `@pragma('vm:entry-point')` function that
/// flutter_foreground_task calls to initialise this isolate.
library;

import 'dart:math';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'core/utils/logger.dart';

// ---------------------------------------------------------------------------
// Isolate entry-point (MUST be top-level + annotated)
// ---------------------------------------------------------------------------

/// Called by flutter_foreground_task to start the background isolate.
@pragma('vm:entry-point')
void startBackgroundCallback() {
  FlutterForegroundTask.setTaskHandler(_BgTaskHandler());
}

// ---------------------------------------------------------------------------
// Task handler implementation
// ---------------------------------------------------------------------------

class _BgTaskHandler extends TaskHandler {
  static const String _tag = 'BgTaskHandler';

  int _executionCount = 0;
  final Random _random = Random();

  // ---------------------------------------------------------------------------
  // TaskHandler overrides
  // ---------------------------------------------------------------------------

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    AppLogger.info(_tag, 'Task started — starter: $starter');
    _executionCount = 0;
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    _executionCount++;
    final stopwatch = Stopwatch()..start();

    AppLogger.info(_tag, 'onRepeatEvent #$_executionCount at $timestamp');

    bool success = false;
    String? errorMessage;

    try {
      // Simulate meaningful work (computation / sensor read / data fetch).
      await _simulateWork();
      success = true;
      AppLogger.info(_tag, 'Task #$_executionCount completed successfully');
    } catch (e, st) {
      errorMessage = e.toString();
      AppLogger.error(_tag, 'Task #$_executionCount failed', e, st);
    } finally {
      stopwatch.stop();
    }

    // Send result back to the UI isolate so the dashboard can update.
    FlutterForegroundTask.sendDataToMain({
      'count': _executionCount,
      'timestamp': timestamp.toIso8601String(),
      'success': success,
      'error': errorMessage,
      'durationMs': stopwatch.elapsedMilliseconds,
    });
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    AppLogger.info(_tag, 'Task destroyed at $timestamp after $_executionCount executions');
  }

  @override
  void onReceiveData(Object data) {
    // Handle commands sent from the UI isolate if needed.
    AppLogger.info(_tag, 'Received data from UI: $data');
  }

  @override
  void onNotificationButtonPressed(String id) {
    AppLogger.info(_tag, 'Notification button pressed: $id');
    if (id == 'stopBtn') {
      FlutterForegroundTask.stopService();
    }
  }

  @override
  void onNotificationPressed() {
    // Bring app to foreground when user taps the notification.
    FlutterForegroundTask.launchApp('/');
    AppLogger.info(_tag, 'Notification pressed — launching app');
  }

  // ---------------------------------------------------------------------------
  // Simulated work
  // ---------------------------------------------------------------------------

  /// Simulates a mix of CPU work and an async delay to mimic real tasks
  /// such as a sensor read, a local DB write, or a lightweight computation.
  Future<void> _simulateWork() async {
    // Occasionally simulate a transient error (10 % chance).
    if (_random.nextInt(10) == 0) {
      throw Exception('Simulated transient error in task #$_executionCount');
    }

    // Simulate ~200 ms of async I/O.
    await Future<void>.delayed(const Duration(milliseconds: 200));

    // Lightweight CPU computation.
    var result = 0;
    for (var i = 0; i < 100000; i++) {
      result += i;
    }
    AppLogger.info(_tag, 'Computation result: $result');
  }
}
