/// Simple logging utility that prefixes messages with a tag and timestamp.
library;

import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();

  static void info(String tag, String message) {
    if (kDebugMode) {
      debugPrint('[INFO][$tag] ${DateTime.now().toIso8601String()} — $message');
    }
  }

  static void warning(String tag, String message) {
    if (kDebugMode) {
      debugPrint('[WARN][$tag] ${DateTime.now().toIso8601String()} — $message');
    }
  }

  static void error(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[ERROR][$tag] ${DateTime.now().toIso8601String()} — $message');
      if (error != null) debugPrint('  error: $error');
      if (stackTrace != null) debugPrint('  stack: $stackTrace');
    }
  }
}
