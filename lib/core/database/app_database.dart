/// SQLite database helper using sqflite.
///
/// Provides CRUD operations for [TaskLog] records and exposes a singleton
/// instance via [AppDatabase.instance].
library;

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../utils/constants.dart';
import '../utils/logger.dart';
import 'models/task_log.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const String _tag = 'AppDatabase';

  Database? _db;

  Future<Database> get database async {
    _db ??= await _openDatabase();
    return _db!;
  }

  Future<Database> _openDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, AppConstants.dbName);

    AppLogger.info(_tag, 'Opening database at $path');

    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    AppLogger.info(_tag, 'Creating database schema v$version');
    await db.execute('''
      CREATE TABLE ${AppConstants.tableTaskLogs} (
        id                    INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp             TEXT    NOT NULL,
        status                TEXT    NOT NULL,
        error_message         TEXT,
        execution_duration_ms INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    AppLogger.info(_tag, 'Upgrading database from v$oldVersion to v$newVersion');
    // Future migrations go here.
  }

  // ---------------------------------------------------------------------------
  // CRUD operations
  // ---------------------------------------------------------------------------

  /// Insert a new [TaskLog] and return its generated id.
  Future<int> insertLog(TaskLog log) async {
    try {
      final db = await database;
      final id = await db.insert(
        AppConstants.tableTaskLogs,
        log.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      AppLogger.info(_tag, 'Inserted log id=$id');
      return id;
    } catch (e, st) {
      AppLogger.error(_tag, 'insertLog failed', e, st);
      rethrow;
    }
  }

  /// Return the [limit] most-recent logs, ordered newest-first.
  Future<List<TaskLog>> getRecentLogs({int limit = AppConstants.maxLogsDisplayed}) async {
    try {
      final db = await database;
      final rows = await db.query(
        AppConstants.tableTaskLogs,
        orderBy: 'id DESC',
        limit: limit,
      );
      return rows.map(TaskLog.fromMap).toList();
    } catch (e, st) {
      AppLogger.error(_tag, 'getRecentLogs failed', e, st);
      return [];
    }
  }

  /// Return total log count.
  Future<int> getTotalCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM ${AppConstants.tableTaskLogs}',
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e, st) {
      AppLogger.error(_tag, 'getTotalCount failed', e, st);
      return 0;
    }
  }

  /// Return success count.
  Future<int> getSuccessCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        "SELECT COUNT(*) as cnt FROM ${AppConstants.tableTaskLogs} WHERE status = 'success'",
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e, st) {
      AppLogger.error(_tag, 'getSuccessCount failed', e, st);
      return 0;
    }
  }

  /// Return failure count.
  Future<int> getFailureCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        "SELECT COUNT(*) as cnt FROM ${AppConstants.tableTaskLogs} WHERE status = 'failure'",
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e, st) {
      AppLogger.error(_tag, 'getFailureCount failed', e, st);
      return 0;
    }
  }

  /// Delete all logs older than [keepCount] entries.
  Future<void> pruneOldLogs({int keepCount = 500}) async {
    try {
      final db = await database;
      await db.rawDelete('''
        DELETE FROM ${AppConstants.tableTaskLogs}
        WHERE id NOT IN (
          SELECT id FROM ${AppConstants.tableTaskLogs}
          ORDER BY id DESC
          LIMIT $keepCount
        )
      ''');
    } catch (e, st) {
      AppLogger.error(_tag, 'pruneOldLogs failed', e, st);
    }
  }

  /// Delete all logs.
  Future<void> clearAllLogs() async {
    try {
      final db = await database;
      await db.delete(AppConstants.tableTaskLogs);
    } catch (e, st) {
      AppLogger.error(_tag, 'clearAllLogs failed', e, st);
    }
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
