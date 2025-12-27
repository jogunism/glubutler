import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:glu_butler/models/report.dart';
import 'package:glu_butler/services/database/database_schema.dart';

/// 리포트 데이터 접근 객체 (DAO)
///
/// 리포트 CRUD 작업을 처리합니다.
class ReportDao {
  final Database db;

  ReportDao(this.db);

  /// 새 리포트 저장
  ///
  /// Returns: 삽입된 리포트의 ID
  Future<int> insertReport(Report report) async {
    // DB lock 에러 재시도 로직
    int retryCount = 0;
    const maxRetries = 3;
    const retryDelay = Duration(milliseconds: 100);

    while (retryCount < maxRetries) {
      try {
        final id = await db.insert(
          DatabaseSchema.tableReports,
          report.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        return id;
      } catch (e) {
        if (e.toString().contains('database is locked') && retryCount < maxRetries - 1) {
          retryCount++;
          debugPrint('[ReportDao] Database locked, retrying ($retryCount/$maxRetries)...');
          await Future.delayed(retryDelay * retryCount);
        } else {
          rethrow;
        }
      }
    }

    throw Exception('Failed to insert report after $maxRetries attempts');
  }

  /// 가장 최근 리포트 조회
  ///
  /// Returns: 가장 최근에 생성된 리포트, 없으면 null
  Future<Report?> getLatestReport() async {
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseSchema.tableReports,
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return Report.fromMap(maps.first);
  }

  /// 모든 리포트 조회 (최신순)
  ///
  /// Returns: 생성일 기준 내림차순으로 정렬된 리포트 리스트
  Future<List<Report>> getAllReports() async {
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseSchema.tableReports,
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return Report.fromMap(maps[i]);
    });
  }

  /// ID로 특정 리포트 조회
  ///
  /// Returns: 해당 ID의 리포트, 없으면 null
  Future<Report?> getReportById(int id) async {
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseSchema.tableReports,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return Report.fromMap(maps.first);
  }

  /// 리포트 삭제
  ///
  /// Returns: 삭제된 행의 수
  Future<int> deleteReport(int id) async {
    return await db.delete(
      DatabaseSchema.tableReports,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 날짜 범위로 리포트 조회
  ///
  /// [startDate]: 검색 시작일
  /// [endDate]: 검색 종료일
  ///
  /// Returns: 해당 기간의 리포트 리스트
  Future<List<Report>> getReportsByDateRange(
      DateTime startDate, DateTime endDate) async {
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseSchema.tableReports,
      where: 'start_date >= ? AND end_date <= ?',
      whereArgs: [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return Report.fromMap(maps[i]);
    });
  }

  /// 모든 리포트 삭제 (테스트용)
  Future<int> deleteAllReports() async {
    return await db.delete(DatabaseSchema.tableReports);
  }

  /// 리포트 개수 조회
  Future<int> getReportCount() async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseSchema.tableReports}',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
