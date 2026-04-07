import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:glu_butler/models/glucose_record.dart';
import 'package:glu_butler/services/health_service.dart';
import 'package:glu_butler/services/database_service.dart';

/// Repository for glucose records.
///
/// Handles the logic of reading/writing glucose data from/to
/// either Apple Health or local database based on permission status.
class GlucoseRepository {
  final HealthService _healthService;
  final DatabaseService _databaseService;

  GlucoseRepository({
    HealthService? healthService,
    DatabaseService? databaseService,
  })  : _healthService = healthService ?? HealthService(),
        _databaseService = databaseService ?? DatabaseService();

  /// Check if HealthKit write permission is granted for blood glucose
  Future<bool> hasHealthWritePermission() async {
    await _healthService.checkPermissionStatus();
    final hasPermission = _healthService.getPermissionStatus(HealthDataType.BLOOD_GLUCOSE);

    // If we have write permission, we can also read - ensure hasRequestedPermissions is true
    if (hasPermission && !_healthService.hasRequestedPermissions) {
      _healthService.setHasRequestedPermissions(true);
    }

    return hasPermission;
  }

  /// Save a glucose record.
  ///
  /// If HealthKit write permission is granted, writes to HealthKit in the
  /// background (fire-and-forget) so the UI is not blocked by the native
  /// HealthKit/Health Connect call. On background failure, falls back to
  /// inserting into the local database so the record is not lost.
  ///
  /// If write permission is not granted, saves to the local database.
  /// Returns true if the save flow was initiated successfully.
  Future<bool> save(GlucoseRecord record) async {
    final hasPermission = await hasHealthWritePermission();

    if (hasPermission) {
      // Fire-and-forget: do not block the UI on the native HealthKit write.
      // If the write fails, fall back to the local DB so the record persists.
      unawaited(
        _healthService.writeGlucoseRecord(record).then((success) async {
          if (!success) {
            await _databaseService.insertGlucose(record);
          }
        }).catchError((Object e, StackTrace st) async {
          debugPrint('[GlucoseRepository] Background health write failed: $e');
          await _databaseService.insertGlucose(record);
        }),
      );
      return true;
    } else {
      // Save to local database
      await _databaseService.insertGlucose(record);
      return true;
    }
  }

  /// Fetch glucose records from the appropriate sources.
  ///
  /// - If HealthKit permissions were requested: fetch from HealthKit + local DB, then merge
  /// - If not: fetch from local DB only
  ///
  /// Returns deduplicated list sorted by timestamp (newest first).
  Future<List<GlucoseRecord>> fetch({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final Map<String, GlucoseRecord> recordsById = {};

    // Fetch from local DB first
    final localRecords = await _databaseService.getGlucoseRecords(
      startDate: startDate,
      endDate: endDate,
    );
    for (final record in localRecords) {
      recordsById[record.id] = record;
    }

    // Fetch from HealthKit/Health Connect if permissions were requested (read permission may exist)
    if (_healthService.hasRequestedPermissions) {
      final healthRecords = await _healthService.fetchGlucoseData(
        startDate: startDate,
        endDate: endDate,
      );
      for (final record in healthRecords) {
        // HealthKit records override local records with same ID
        // (in case of migration where we wrote local to HealthKit)
        recordsById[record.id] = record;
      }
    }

    // Sort by timestamp (newest first)
    final allRecords = recordsById.values.toList();
    allRecords.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return allRecords;
  }

  /// Delete a glucose record from local database.
  Future<void> delete(String id) async {
    await _databaseService.deleteGlucose(id);
  }

  /// Migrate all local glucose records to HealthKit.
  ///
  /// Called when user grants HealthKit write permission.
  /// Successfully migrated records are deleted from local DB via batch delete.
  /// Failed records remain in local DB for retry on next app startup.
  ///
  /// Returns (attemptedCount, successCount) tuple.
  Future<(int, int)> migrateLocalToHealth() async {
    final hasPermission = await hasHealthWritePermission();
    if (!hasPermission) {
      return (0, 0);
    }

    // Get all local records (no date filter - migrate everything)
    final localRecords = await _databaseService.getGlucoseRecords();

    // Filter to only non-HealthKit records
    final recordsToMigrate = localRecords.where((r) => !r.isFromHealthKit).toList();
    if (recordsToMigrate.isEmpty) {
      return (0, 0);
    }

    // Collect successfully migrated record IDs
    final List<String> migratedIds = [];

    for (final record in recordsToMigrate) {
      final success = await _healthService.writeGlucoseRecord(record);
      if (success) {
        migratedIds.add(record.id);
      }
    }

    // Batch delete all successfully migrated records
    if (migratedIds.isNotEmpty) {
      await _databaseService.deleteGlucoseByIds(migratedIds);
    }

    return (recordsToMigrate.length, migratedIds.length);
  }

  /// Get count of local (non-HealthKit) records.
  Future<int> getLocalRecordCount() async {
    final records = await _databaseService.getGlucoseRecords();
    return records.where((r) => !r.isFromHealthKit).length;
  }
}
