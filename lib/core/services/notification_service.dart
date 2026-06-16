/// Notification helper that wraps flutter_foreground_task notification setup.
///
/// On Android a LOW-priority notification channel is used so the persistent
/// service notification is as unobtrusive as possible.
/// On iOS notifications from the foreground task are suppressed.
library;

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../utils/constants.dart';
import '../utils/logger.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  static const String _tag = 'NotificationService';

  /// Initialises the flutter_foreground_task notification options.
  ///
  /// Must be called once before starting the foreground service.
  void init() {
    AppLogger.info(_tag, 'Initialising notification options');

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: AppConstants.notificationChannelId,
        channelName: AppConstants.notificationChannelName,
        channelDescription: AppConstants.notificationChannelDesc,
        // LOW importance: no sound, collapsed, non-intrusive.
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
        buttons: [
          const NotificationButton(id: 'stopBtn', text: 'Stop'),
        ],
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(
          AppConstants.taskIntervalMs,
        ),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }
}
