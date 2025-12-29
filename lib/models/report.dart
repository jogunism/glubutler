/// AI 리포트 모델
class Report {
  final int? id;
  final DateTime startDate;
  final DateTime endDate;
  final String content; // Markdown 형식
  final DateTime createdAt;

  Report({
    this.id,
    required this.startDate,
    required this.endDate,
    required this.content,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 데이터베이스에서 읽어온 Map을 Report 객체로 변환
  factory Report.fromMap(Map<String, dynamic> map) {
    return Report(
      id: map['id'] as int?,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Report 객체를 데이터베이스에 저장할 Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// 리포트 기간 문자열 반환 (예: "12월 28일 - 29일" 또는 "11월 30일 - 12월 2일")
  String getPeriodString() {
    final start = '${startDate.month}월 ${startDate.day}일';
    // 같은 달이면 월 생략
    final end = startDate.month == endDate.month
        ? '${endDate.day}일'
        : '${endDate.month}월 ${endDate.day}일';
    return '$start - $end';
  }

  /// copyWith 메서드
  Report copyWith({
    int? id,
    DateTime? startDate,
    DateTime? endDate,
    String? content,
    DateTime? createdAt,
  }) {
    return Report(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
