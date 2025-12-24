import 'package:glu_butler/models/diary_file.dart';

/// 일기 엔트리 모델
///
/// 사용자가 작성한 일기를 나타냅니다.
/// 여러 개의 파일 첨부를 가질 수 있습니다 (1:N 관계)
class DiaryEntry {
  final String id;
  final String content;
  final DateTime timestamp;
  final DateTime createdAt;
  final List<DiaryFile> files;

  DiaryEntry({
    required this.id,
    required this.content,
    required this.timestamp,
    required this.createdAt,
    this.files = const [],
  });

  /// SQLite 맵으로부터 생성
  factory DiaryEntry.fromMap(Map<String, dynamic> map, {List<DiaryFile>? files}) {
    return DiaryEntry(
      id: map['id'] as String,
      content: map['content'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      files: files ?? [],
    );
  }

  /// SQLite 맵으로 변환
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  DiaryEntry copyWith({
    String? id,
    String? content,
    DateTime? timestamp,
    DateTime? createdAt,
    List<DiaryFile>? files,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      createdAt: createdAt ?? this.createdAt,
      files: files ?? this.files,
    );
  }
}
