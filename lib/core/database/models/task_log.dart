/// Data model representing a single background task execution log entry.
library;

/// Status values for a task execution.
enum TaskStatus { success, failure }

extension TaskStatusExtension on TaskStatus {
  String get label => name; // 'success' or 'failure'

  static TaskStatus fromString(String value) {
    return TaskStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TaskStatus.failure,
    );
  }
}

/// A single row in the [AppConstants.tableTaskLogs] table.
class TaskLog {
  final int? id;
  final DateTime timestamp;
  final TaskStatus status;
  final String? errorMessage;
  final int executionDurationMs;

  const TaskLog({
    this.id,
    required this.timestamp,
    required this.status,
    this.errorMessage,
    required this.executionDurationMs,
  });

  // --- Serialisation ----------------------------------------------------------

  factory TaskLog.fromMap(Map<String, dynamic> map) {
    return TaskLog(
      id: map['id'] as int?,
      timestamp: DateTime.parse(map['timestamp'] as String),
      status: TaskStatusExtension.fromString(map['status'] as String),
      errorMessage: map['error_message'] as String?,
      executionDurationMs: map['execution_duration_ms'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'error_message': errorMessage,
      'execution_duration_ms': executionDurationMs,
    };
  }

  // --- Convenience ------------------------------------------------------------

  bool get isSuccess => status == TaskStatus.success;

  @override
  String toString() =>
      'TaskLog(id: $id, timestamp: $timestamp, status: ${status.name}, '
      'durationMs: $executionDurationMs)';
}
