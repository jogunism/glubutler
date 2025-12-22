import 'package:sqflite/sqflite.dart';

import 'database_schema.dart';

/// Health permission type
enum HealthPermissionType {
  readWrite,
  readOnly,
  denied,
}

/// Health connection info model
class HealthConnectionInfo {
  final bool isConnected;
  final int syncPeriodDays;
  final DateTime? connectedAt;
  final DateTime updatedAt;

  HealthConnectionInfo({
    required this.isConnected,
    required this.syncPeriodDays,
    this.connectedAt,
    required this.updatedAt,
  });

  HealthConnectionInfo copyWith({
    bool? isConnected,
    int? syncPeriodDays,
    DateTime? connectedAt,
    DateTime? updatedAt,
  }) {
    return HealthConnectionInfo(
      isConnected: isConnected ?? this.isConnected,
      syncPeriodDays: syncPeriodDays ?? this.syncPeriodDays,
      connectedAt: connectedAt ?? this.connectedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Data Access Object for health connection and permissions
class HealthDao {
  final Database db;

  HealthDao(this.db);

  // ============ Health Connection ============

  /// Get health connection status
  Future<HealthConnectionInfo> getHealthConnection() async {
    final maps = await db.query(
      DatabaseSchema.tableHealthConnection,
      where: 'id = 1',
    );

    if (maps.isEmpty) {
      return HealthConnectionInfo(
        isConnected: false,
        syncPeriodDays: 7,
        connectedAt: null,
        updatedAt: DateTime.now(),
      );
    }

    return _mapToHealthConnection(maps.first);
  }

  /// Save or update health connection (upsert)
  Future<void> saveHealthConnection(HealthConnectionInfo info) async {
    await db.insert(
      DatabaseSchema.tableHealthConnection,
      _healthConnectionToMap(info),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update only sync period
  Future<void> updateSyncPeriod(int days) async {
    final now = DateTime.now().toIso8601String();

    final existing = await db.query(
      DatabaseSchema.tableHealthConnection,
      where: 'id = 1',
    );

    if (existing.isEmpty) {
      await db.insert(DatabaseSchema.tableHealthConnection, {
        'id': 1,
        'is_connected': 0,
        'sync_period_days': days,
        'connected_at': null,
        'updated_at': now,
      });
    } else {
      await db.update(
        DatabaseSchema.tableHealthConnection,
        {'sync_period_days': days, 'updated_at': now},
        where: 'id = 1',
      );
    }
  }

  Map<String, dynamic> _healthConnectionToMap(HealthConnectionInfo info) {
    return {
      'id': 1,
      'is_connected': info.isConnected ? 1 : 0,
      'sync_period_days': info.syncPeriodDays,
      'connected_at': info.connectedAt?.toIso8601String(),
      'updated_at': info.updatedAt.toIso8601String(),
    };
  }

  HealthConnectionInfo _mapToHealthConnection(Map<String, dynamic> map) {
    return HealthConnectionInfo(
      isConnected: (map['is_connected'] as int) == 1,
      syncPeriodDays: map['sync_period_days'] as int,
      connectedAt: map['connected_at'] != null
          ? DateTime.parse(map['connected_at'] as String)
          : null,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // ============ Health Permissions ============

  /// Get all health permissions
  Future<Map<String, HealthPermissionType>> getHealthPermissions() async {
    final maps = await db.query(DatabaseSchema.tableHealthPermissions);

    final result = <String, HealthPermissionType>{};
    for (final map in maps) {
      final category = map['category'] as String;
      final typeStr = map['permission_type'] as String;
      result[category] = HealthPermissionType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => HealthPermissionType.denied,
      );
    }
    return result;
  }

  /// Get permission for a specific category
  Future<HealthPermissionType?> getHealthPermission(String category) async {
    final maps = await db.query(
      DatabaseSchema.tableHealthPermissions,
      where: 'category = ?',
      whereArgs: [category],
    );

    if (maps.isEmpty) return null;

    final typeStr = maps.first['permission_type'] as String;
    return HealthPermissionType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => HealthPermissionType.denied,
    );
  }

  /// Save or update a single permission
  Future<void> saveHealthPermission(
      String category, HealthPermissionType type) async {
    await db.insert(
      DatabaseSchema.tableHealthPermissions,
      {
        'category': category,
        'permission_type': type.name,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Save multiple permissions at once
  Future<void> saveHealthPermissions(
      Map<String, HealthPermissionType> permissions) async {
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();

    for (final entry in permissions.entries) {
      batch.insert(
        DatabaseSchema.tableHealthPermissions,
        {
          'category': entry.key,
          'permission_type': entry.value.name,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Clear all permissions
  Future<void> clearHealthPermissions() async {
    await db.delete(DatabaseSchema.tableHealthPermissions);
  }
}
