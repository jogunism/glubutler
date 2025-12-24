import 'package:flutter/foundation.dart';

import 'package:glu_butler/models/diary_entry.dart';
import 'package:glu_butler/models/diary_file.dart';
import 'package:glu_butler/services/database_service.dart';

/// Repository for diary entries and files.
///
/// Handles reading/writing diary data to local database.
class DiaryRepository {
  final DatabaseService _databaseService;

  DiaryRepository({
    DatabaseService? databaseService,
  }) : _databaseService = databaseService ?? DatabaseService();

  /// Save a diary entry with optional files.
  ///
  /// Returns true if save was successful.
  Future<bool> save(DiaryEntry entry) async {
    try {
      await _databaseService.insertDiary(entry);

      // Insert files if any
      if (entry.files.isNotEmpty) {
        for (final file in entry.files) {
          await _databaseService.insertDiaryFile(file);
        }
      }

      return true;
    } catch (e) {
      debugPrint('[DiaryRepository] Failed to save diary: $e');
      return false;
    }
  }

  /// Fetch diary entries with their files.
  ///
  /// Returns list sorted by timestamp (newest first).
  Future<List<DiaryEntry>> fetch({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final entries = await _databaseService.getDiaryEntries(
      startDate: startDate,
      endDate: endDate,
    );

    // Load files for each entry
    final entriesWithFiles = <DiaryEntry>[];
    for (final entry in entries) {
      final files = await _databaseService.getDiaryFiles(entry.id);
      entriesWithFiles.add(entry.copyWith(files: files));
    }

    return entriesWithFiles;
  }

  /// Fetch a single diary entry by ID with its files.
  Future<DiaryEntry?> fetchById(String id) async {
    final entry = await _databaseService.getDiaryEntry(id);
    if (entry == null) return null;

    final files = await _databaseService.getDiaryFiles(id);
    return entry.copyWith(files: files);
  }

  /// Delete a diary entry and its files (CASCADE).
  Future<void> delete(String id) async {
    await _databaseService.deleteDiary(id);
  }

  /// Update a diary entry.
  Future<bool> update(DiaryEntry entry) async {
    try {
      await _databaseService.updateDiary(entry);
      return true;
    } catch (e) {
      debugPrint('[DiaryRepository] Failed to update diary: $e');
      return false;
    }
  }
}
