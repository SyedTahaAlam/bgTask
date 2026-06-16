/// App lifecycle observer.
///
/// Handles transitions between foreground and background states so the app can
/// respond appropriately (e.g. refresh the dashboard when coming back to
/// foreground after a long background session).
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/utils/logger.dart';
import 'features/dashboard/controller/dashboard_controller.dart';

class AppLifecycleObserver extends WidgetsBindingObserver {
  static const String _tag = 'AppLifecycleObserver';

  AppLifecycleObserver() {
    WidgetsBinding.instance.addObserver(this);
    AppLogger.info(_tag, 'Observer registered');
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppLogger.info(_tag, 'Observer removed');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    AppLogger.info(_tag, 'Lifecycle state changed: $state');

    switch (state) {
      case AppLifecycleState.resumed:
        // Refresh stats when user brings the app to the foreground.
        _refreshDashboard();
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _refreshDashboard() {
    try {
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().refreshStats();
      }
    } catch (e, st) {
      AppLogger.error(_tag, 'Error refreshing dashboard', e, st);
    }
  }
}
