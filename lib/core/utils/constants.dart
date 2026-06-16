/// App-wide constants for the background task application.
library;

class AppConstants {
  AppConstants._();

  // App identification
  static const String appId = 'com.example.bgtask';
  static const String appName = 'BgTask';

  // Foreground service notification
  static const String notificationChannelId = 'bg_task_foreground_channel';
  static const String notificationChannelName = 'Background Service';
  static const String notificationChannelDesc = 'Keeps the background task running';
  static const String notificationTitle = 'BgTask Service';
  static const String notificationText = 'Running in background';

  // Task execution
  static const int taskIntervalMs = 5000; // 5 seconds
  static const int workManagerIntervalMinutes = 15;

  // WorkManager task names
  static const String wmTaskName = 'persistentBackgroundCheck';
  static const String wmUniqueTaskName = '$appId.persistentCheck';

  // iOS BGTaskScheduler identifier
  static const String iosBackgroundTaskId = '$appId.backgroundtask';

  // Database
  static const String dbName = 'bgtask.db';
  static const int dbVersion = 1;
  static const String tableTaskLogs = 'task_logs';

  // Dashboard
  static const int maxLogsDisplayed = 50;

  // SendPort key used for isolate communication
  static const String sendPortKey = 'bg_task_send_port';
}
