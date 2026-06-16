# Flutter Background Task Application

A complete Flutter application demonstrating persistent foreground and background task execution on both Android and iOS, with auto-restart capabilities after OS process termination.

## Features

- ✅ **Foreground Service** - Runs tasks with minimal, silent notifications
- ✅ **Background Execution** - Continues running even when app is in background
- ✅ **Auto-Restart** - Automatically restarts after OS kills the process
- ✅ **Device Reboot Handling** - Service restarts after device reboot
- ✅ **Cross-Platform** - Works on both Android and iOS
- ✅ **Task Dashboard** - Real-time execution metrics and statistics
- ✅ **Local Database** - SQLite logging of task executions
- ✅ **Error Handling** - Comprehensive error handling and recovery

## Getting Started

### Prerequisites

- Flutter SDK (v3.0+)
- Android SDK (API 21+)
- Xcode (for iOS development)
- CocoaPods (for iOS dependencies)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/SyedTahaAlam/bgTask.git
cd bgTask
```

2. Install dependencies:
```bash
flutter pub get
```

3. For iOS, install pods:
```bash
cd ios
pod install
cd ..
```

### Running the App

```bash
flutter run
```

## Architecture

### Android Implementation
- **FlutterForegroundTask** - Manages foreground service and background task execution
- **WorkManager** - Handles auto-restart after process kill (15-minute intervals)
- **BootReceiver** - Listens for device boot and restarts service
- **Notification Channel** - LOW priority for minimal distraction

### iOS Implementation
- **BGTaskScheduler** - Schedules background processing tasks
- **App Delegate** - Registers and manages background task lifecycle
- **Background Modes** - Configured for fetch and processing

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── core/
│   ├── database/
│   │   ├── app_database.dart         # SQLite database setup
│   │   └── models/
│   │       └── task_log.dart         # Task execution log model
│   ├── services/
│   │   ├── background_service.dart   # Background task manager
│   │   ├── workmanager_service.dart  # WorkManager integration
│   │   └── notification_service.dart # Notification management
│   └── utils/
│       ├── constants.dart            # App constants
│       └── extensions.dart           # Utility extensions
├── features/
│   ├── dashboard/
│   │   ├── pages/
│   │   │   └── dashboard_page.dart   # Main dashboard UI
│   │   ├── widgets/
│   │   │   ├── stats_card.dart       # Statistics display
│   │   │   ├── task_logs_view.dart   # Task execution logs
│   │   │   └── control_panel.dart    # Start/stop controls
│   │   └── controller/
│   │       └── dashboard_controller.dart # State management
│   └── settings/
│       └── settings_page.dart        # App settings
├── background_task.dart              # Background isolate handler
└── app_lifecycle.dart                # App lifecycle management

android/
├── app/src/main/
│   ├── AndroidManifest.xml           # Android permissions & manifest
│   ├── java/com/example/bgtask/
│   │   └── BootReceiver.kt           # Boot completion receiver
│   └── res/values/
│       └── strings.xml               # Android resources

ios/
├── Runner/
│   ├── AppDelegate.swift             # iOS app delegate
│   ├── Info.plist                    # iOS configuration
│   └── GeneratedPluginRegistrant.h   # Plugin registration
```

## Configuration

### Android Manifest Changes

The app requires these permissions in `AndroidManifest.xml`:
- `FOREGROUND_SERVICE`
- `FOREGROUND_SERVICE_DATA_SYNC`
- `RECEIVE_BOOT_COMPLETED`
- `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`

### iOS Info.plist

Required background modes:
- `fetch` - For periodic background fetch
- `processing` - For extended background processing

## Usage

1. **Start the Service**
   - Open the app
   - Tap "Start Service" button
   - The app will request battery optimization exemption (Android)

2. **Monitor Execution**
   - View real-time task execution count
   - Check last execution timestamp
   - Review success/failure statistics

3. **View Logs**
   - Scroll through task execution history
   - Each log entry shows timestamp and status

4. **Stop the Service**
   - Tap "Stop Service" button
   - Service will be stopped immediately

## Known Limitations

### iOS
- Apple restricts background execution
- BGTaskScheduler can trigger roughly every 15 minutes when app is backgrounded
- No true auto-restart after force-kill (iOS limitation)
- App must be installed from App Store for some background features

### Android
- WorkManager minimum interval is 15 minutes for periodic tasks
- May be throttled by Doze/Battery Optimization on some devices
- Foreground notification must be visible (required by Android OS)

## Testing

### Manual Testing Checklist

1. **Background Execution**
   - [ ] Start service
   - [ ] Press home button to background app
   - [ ] Verify task continues executing (check logs after 30 seconds)

2. **Process Kill**
   - [ ] Start service
   - [ ] Swipe app from recent apps (Android)
   - [ ] Wait 15+ minutes
   - [ ] App automatically restarts service (Android WorkManager)

3. **Device Reboot**
   - [ ] Start service
   - [ ] Restart device
   - [ ] Service automatically restarts (requires warm boot)

4. **Battery Optimization**
   - [ ] Request battery optimization exemption
   - [ ] Enable battery saver mode
   - [ ] Verify task continues running

## Troubleshooting

### Service Not Starting
- Check Android permissions in Settings > Apps > YourApp > Permissions
- Verify battery optimization is disabled
- Check logcat: `flutter logs`

### Tasks Not Executing
- iOS: Ensure app was installed via App Store (simulator has limitations)
- Android: Check if device is in Doze mode
- Verify WorkManager is registered (Android)

### Notification Issues
- Android: Notification is required; you can collapse it
- iOS: Notification is not shown

## Dependencies

- `flutter_foreground_task: ^8.0.0` - Foreground service
- `workmanager: ^0.5.2` - Background task scheduling
- `background_fetch: ^1.2.0` - iOS background execution
- `get_it: ^7.6.0` - Service locator
- `sqflite: ^2.3.0` - Local SQLite database
- `path_provider: ^2.1.0` - File system access

## Contributing

Feel free to submit issues and enhancement requests!

## License

MIT License - See LICENSE file for details

## Support

For issues and questions, please open an issue on GitHub.
