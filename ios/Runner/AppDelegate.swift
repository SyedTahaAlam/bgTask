import UIKit
import Flutter
import BackgroundTasks

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

    /// Identifier used for BGProcessingTaskRequest.
    private let backgroundTaskIdentifier = "com.example.bgtask.backgroundtask"

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        GeneratedPluginRegistrant.register(with: self)

        // Register the BGProcessingTask identifier.
        // This MUST match the value in Info.plist under
        // BGTaskSchedulerPermittedIdentifiers.
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: backgroundTaskIdentifier,
            using: nil
        ) { [weak self] task in
            guard let self = self,
                  let processingTask = task as? BGProcessingTask else {
                task.setTaskCompleted(success: false)
                return
            }
            self.handleBackgroundTask(task: processingTask)
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // MARK: - Background Task Handling

    /// Handles the BGProcessingTask, reschedules on completion.
    private func handleBackgroundTask(task: BGProcessingTask) {
        // Immediately schedule the next run so background execution continues.
        scheduleBackgroundTask()

        task.expirationHandler = {
            // Called when the system needs to reclaim resources.
            task.setTaskCompleted(success: false)
        }

        // Perform any lightweight background work here if needed.
        // flutter_foreground_task / background_fetch handles the heavy lifting
        // from the Dart side; this handler keeps the BGTaskScheduler pipeline
        // alive.
        task.setTaskCompleted(success: true)
    }

    /// Submits a new BGProcessingTaskRequest so background execution continues.
    private func scheduleBackgroundTask() {
        let request = BGProcessingTaskRequest(identifier: backgroundTaskIdentifier)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        // Earliest begin date ~1 minute from now; the OS decides the actual
        // launch time based on system conditions.
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60)

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            NSLog("[AppDelegate] Failed to schedule background task: \(error)")
        }
    }

    // MARK: - App Lifecycle

    override func applicationDidEnterBackground(_ application: UIApplication) {
        // Schedule a background task whenever the app moves to background.
        scheduleBackgroundTask()
    }
}
