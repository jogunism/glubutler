/// 일기 첨부 파일 모델
///
/// 일기 엔트리에 첨부된 파일(주로 사진)을 나타냅니다.
/// EXIF 메타데이터(위치, 촬영시간)를 포함합니다.
class DiaryFile {
  final String id;
  final String diaryId;
  final String filePath;
  final double? latitude;
  final double? longitude;
  final DateTime? capturedAt;
  final int? fileSize;
  final DateTime createdAt;

  DiaryFile({
    required this.id,
    required this.diaryId,
    required this.filePath,
    this.latitude,
    this.longitude,
    this.capturedAt,
    this.fileSize,
    required this.createdAt,
  });

  /// SQLite 맵으로부터 생성
  factory DiaryFile.fromMap(Map<String, dynamic> map) {
    return DiaryFile(
      id: map['id'] as String,
      diaryId: map['diary_id'] as String,
      filePath: map['file_path'] as String,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      capturedAt: map['captured_at'] != null
          ? DateTime.parse(map['captured_at'] as String)
          : null,
      fileSize: map['file_size'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// SQLite 맵으로 변환
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'diary_id': diaryId,
      'file_path': filePath,
      'latitude': latitude,
      'longitude': longitude,
      'captured_at': capturedAt?.toIso8601String(),
      'file_size': fileSize,
      'created_at': createdAt.toIso8601String(),
    };
  }

  DiaryFile copyWith({
    String? id,
    String? diaryId,
    String? filePath,
    double? latitude,
    double? longitude,
    DateTime? capturedAt,
    int? fileSize,
    DateTime? createdAt,
  }) {
    return DiaryFile(
      id: id ?? this.id,
      diaryId: diaryId ?? this.diaryId,
      filePath: filePath ?? this.filePath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      capturedAt: capturedAt ?? this.capturedAt,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
