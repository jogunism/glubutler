import 'package:flutter/foundation.dart';

import 'package:glu_butler/models/insulin_record.dart';
import 'package:glu_butler/services/health_service.dart';
import 'package:glu_butler/services/database_service.dart';

/// Repository for insulin records.
///
/// Handles the logic of reading/writing insulin data from/to
/// either Apple Health or local database based on permission status.
class InsulinRepository {
  final HealthService _healthService;
  final DatabaseService _databaseService;

  InsulinRepository({
    HealthService? healthService,
    DatabaseService? databaseService,
  })  : _healthService = healthService ?? HealthService(),
        _databaseService = databaseService ?? DatabaseService();

  /// Check if HealthKit write permission is granted for insulin
  Future<bool> hasHealthWritePermission() async {
    await _healthService.checkPermissionStatus();
    return _healthService.getPermissionStatus(HealthDataType.INSULIN_DELIVERY);
  }

  /// Save an insulin record.
  ///
  /// If HealthKit write permission is granted, writes to HealthKit.
  /// Otherwise, saves to local database.
  /// Returns true if save was successful.
  Future<bool> save(InsulinRecord record) async {
    final hasPermission = await hasHealthWritePermission();

    if (hasPermission) {
      // Write to HealthKit
      final success = await _healthService.writeInsulinRecord(record);
      if (success) {
        return true;
      } else {
        // Fallback to local DB if HealthKit write fails
        debugPrint('[InsulinRepository] HealthKit write failed, falling back to local DB');
        await _databaseService.insertInsulin(record);
        return true;
      }
    } else {
      // Save to local database
      await _databaseService.insertInsulin(record);
      return true;
    }
  }

  /// Fetch insulin records from the appropriate sources.
  ///
  /// - If HealthKit permissions were requested: fetch from HealthKit + local DB, then merge
  /// - If not: fetch from local DB only
  ///
  /// Returns deduplicated list sorted by timestamp (newest first).
  Future<List<InsulinRecord>> fetch({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final Map<String, InsulinRecord> recordsById = {};

    // Fetch from local DB first
    final localRecords = await _databaseService.getInsulinRecords(
      startDate: startDate,
      endDate: endDate,
    );
    for (final record in localRecords) {
      recordsById[record.id] = record;
    }

    // Fetch from HealthKit if permissions were requested (read permission may exist)
    if (_healthService.hasRequestedPermissions) {
      final healthRecords = await _healthService.fetchInsulinData(
        startDate: startDate,
        endDate: endDate,
      );
      for (final record in healthRecords) {
        // HealthKit records override local records with same ID
        recordsById[record.id] = record;
      }
    }

    // Sort by timestamp (newest first)
    final allRecords = recordsById.values.toList();
    allRecords.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return allRecords;
  }

  /// Delete an insulin record from local database.
  Future<void> delete(String id) async {
    await _databaseService.deleteInsulin(id);
  }

  /// Migrate all local insulin records to HealthKit.
  ///
  /// Called when user grants HealthKit write permission.
  /// Successfully migrated records are deleted from local DB via batch delete.
  /// Failed records remain in local DB for retry on next app startup.
  ///
  /// Returns (attemptedCount, successCount) tuple.
  Future<(int, int)> migrateLocalToHealth() async {
    final hasPermission = await hasHealthWritePermission();
    if (!hasPermission) {
      debugPrint('[InsulinRepository] No write permission, cannot migrate');
      return (0, 0);
    }

    // Get all local records (no date filter - migrate everything)
    final localRecords = await _databaseService.getInsulinRecords();

    // Filter to only non-HealthKit records
    final recordsToMigrate = localRecords.where((r) => !r.isFromHealthKit).toList();
    if (recordsToMigrate.isEmpty) {
      debugPrint('[InsulinRepository] No local records to migrate');
      return (0, 0);
    }

    // Collect successfully migrated record IDs
    final List<String> migratedIds = [];

    for (final record in recordsToMigrate) {
      final success = await _healthService.writeInsulinRecord(record);
      if (success) {
        migratedIds.add(record.id);
      } else {
        debugPrint('[InsulinRepository] Failed to migrate: ${record.id}');
      }
    }

    // Batch delete all successfully migrated records
    if (migratedIds.isNotEmpty) {
      await _databaseService.deleteInsulinByIds(migratedIds);
    }

    debugPrint('[InsulinRepository] Migrated ${migratedIds.length}/${recordsToMigrate.length} records to HealthKit');
    return (recordsToMigrate.length, migratedIds.length);
  }

  /// Get count of local (non-HealthKit) records.
  Future<int> getLocalRecordCount() async {
    final records = await _databaseService.getInsulinRecords();
    return records.where((r) => !r.isFromHealthKit).length;
  }
}
