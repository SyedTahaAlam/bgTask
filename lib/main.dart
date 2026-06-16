/// Application entry point.
///
/// Wraps the root widget in [WithForegroundTask] so that
/// flutter_foreground_task can manage the lifecycle of the foreground service
/// and the background isolate.
library;

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:get/get.dart';

import 'app_lifecycle.dart';
import 'features/dashboard/pages/dashboard_page.dart';
import 'features/dashboard/controller/dashboard_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Register the DashboardController early so it is available globally.
  Get.put(DashboardController());

  runApp(const BgTaskApp());
}

class BgTaskApp extends StatefulWidget {
  const BgTaskApp({super.key});

  @override
  State<BgTaskApp> createState() => _BgTaskAppState();
}

class _BgTaskAppState extends State<BgTaskApp> {
  late final AppLifecycleObserver _lifecycleObserver;

  @override
  void initState() {
    super.initState();
    _lifecycleObserver = AppLifecycleObserver();
  }

  @override
  void dispose() {
    _lifecycleObserver.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WithForegroundTask(
      child: GetMaterialApp(
        title: 'BgTask',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2196F3),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2196F3),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: const DashboardPage(),
      ),
    );
  }
}
