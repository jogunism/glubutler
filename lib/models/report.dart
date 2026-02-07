/// AI 리포트 모델
class Report {
  final int? id;
  final DateTime startDate;
  final DateTime endDate;
  final String? content; // Markdown 형식 (삭제된 리포트는 빈 문자열)
  final String? improvements; // 잘하고 계신점
  final String? needsImprovement; // 개선이 필요한 부분
  final DateTime createdAt;

  Report({
    this.id,
    required this.startDate,
    required this.endDate,
    this.content,
    this.improvements,
    this.needsImprovement,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 데이터베이스에서 읽어온 Map을 Report 객체로 변환
  factory Report.fromMap(Map<String, dynamic> map) {
    final contentStr = map['content'] as String?;
    final improvementsStr = map['improvements'] as String?;
    final needsImprovementStr = map['needs_improvement'] as String?;
    return Report(
      id: map['id'] as int?,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      content: (contentStr == null || contentStr.isEmpty) ? null : contentStr,
      improvements: (improvementsStr == null || improvementsStr.isEmpty) ? null : improvementsStr,
      needsImprovement: (needsImprovementStr == null || needsImprovementStr.isEmpty) ? null : needsImprovementStr,
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
      'improvements': improvements,
      'needs_improvement': needsImprovement,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// 리포트 기간 문자열 반환 (예: "12월 28일 - 29일" 또는 "11월 30일 - 12월 2일")
  /// [monthLabel]과 [dayLabel]을 전달하여 국제화 지원
  /// 영어 등 레이블이 필요 없는 언어는 빈 문자열 전달
  String getPeriodString({String monthLabel = '월', String dayLabel = '일'}) {
    final hasLabel = monthLabel.isNotEmpty || dayLabel.isNotEmpty;

    if (hasLabel) {
      // 한국어, 일본어, 중국어 등: "1월 10일 - 11일"
      final start = '${startDate.month}$monthLabel ${startDate.day}$dayLabel';
      final end = startDate.month == endDate.month
          ? '${endDate.day}$dayLabel'
          : '${endDate.month}$monthLabel ${endDate.day}$dayLabel';
      return '$start - $end';
    } else {
      // 영어, 유럽 언어 등: "Jan 10 - 11" 또는 "Nov 30 - Dec 2"
      final monthNames = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final startMonth = monthNames[startDate.month];
      final endMonth = monthNames[endDate.month];

      final start = '$startMonth ${startDate.day}';
      final end = startDate.month == endDate.month
          ? '${endDate.day}'
          : '$endMonth ${endDate.day}';
      return '$start - $end';
    }
  }

  /// copyWith 메서드
  Report copyWith({
    int? id,
    DateTime? startDate,
    DateTime? endDate,
    String? content,
    String? improvements,
    String? needsImprovement,
    DateTime? createdAt,
  }) {
    return Report(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      content: content ?? this.content,
      improvements: improvements ?? this.improvements,
      needsImprovement: needsImprovement ?? this.needsImprovement,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
