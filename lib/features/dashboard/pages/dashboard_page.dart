/// Main dashboard page that assembles all dashboard widgets.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controller/dashboard_controller.dart';
import '../widgets/control_panel.dart';
import '../widgets/stats_card.dart';
import '../widgets/task_logs_view.dart';
import '../../settings/settings_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM, HH:mm:ss');
    // Lazily put the controller if not already registered.
    if (!Get.isRegistered<DashboardController>()) {
      Get.put(DashboardController());
    }
    final controller = Get.find<DashboardController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('BgTask Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.executionCount.value == 0) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: controller.refreshStats,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Control Panel ─────────────────────────────────────────
                const ControlPanel(),
                const SizedBox(height: 20),

                // ── Stats Grid ────────────────────────────────────────────
                Text(
                  'Statistics',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    Obx(() => StatsCard(
                          label: 'Total Executions',
                          value: '${controller.executionCount.value}',
                          icon: Icons.repeat,
                          color: theme.colorScheme.primary,
                        )),
                    Obx(() => StatsCard(
                          label: 'Success Rate',
                          value: '${controller.successRate.toStringAsFixed(1)}%',
                          icon: Icons.check_circle_outline,
                          color: Colors.green,
                          subtitle:
                              '${controller.successCount.value} / ${controller.executionCount.value}',
                        )),
                    Obx(() => StatsCard(
                          label: 'Failures',
                          value: '${controller.failureCount.value}',
                          icon: Icons.error_outline,
                          color: Colors.red,
                        )),
                    Obx(() {
                      final last = controller.lastExecutionTime.value;
                      return StatsCard(
                        label: 'Last Execution',
                        value: last != null ? dateFormat.format(last) : '—',
                        icon: Icons.access_time,
                        color: theme.colorScheme.secondary,
                      );
                    }),
                  ],
                ),

                const SizedBox(height: 20),
                // ── Log List ──────────────────────────────────────────────
                const TaskLogsView(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      }),
    );
  }
}
