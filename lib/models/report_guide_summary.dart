import 'dart:convert';

/// 리포트 가이드 요약 모델
///
/// 서버에 연속성 있는 리포트 생성을 위해 전달하는 이전 리포트 가이드 요약
class ReportGuideSummary {
  final int? id;
  final String reportDate; // yyyy-MM-dd 형식
  final List<String> improvements; // 잘하고 계신점
  final List<String> needsImprovement; // 개선이 필요한 부분
  final DateTime createdAt;

  ReportGuideSummary({
    this.id,
    required this.reportDate,
    required this.improvements,
    required this.needsImprovement,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 데이터베이스에서 읽어온 Map을 ReportGuideSummary 객체로 변환
  factory ReportGuideSummary.fromMap(Map<String, dynamic> map) {
    return ReportGuideSummary(
      id: map['id'] as int?,
      reportDate: map['report_date'] as String,
      improvements: (jsonDecode(map['improvements'] as String) as List<dynamic>)
          .cast<String>(),
      needsImprovement:
          (jsonDecode(map['needs_improvement'] as String) as List<dynamic>)
              .cast<String>(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// ReportGuideSummary 객체를 데이터베이스에 저장할 Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'report_date': reportDate,
      'improvements': jsonEncode(improvements),
      'needs_improvement': jsonEncode(needsImprovement),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// 서버 API 전송용 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'reportDate': reportDate,
      'improvements': improvements,
      'needsImprovement': needsImprovement,
    };
  }

  /// copyWith 메서드
  ReportGuideSummary copyWith({
    int? id,
    String? reportDate,
    List<String>? improvements,
    List<String>? needsImprovement,
    DateTime? createdAt,
  }) {
    return ReportGuideSummary(
      id: id ?? this.id,
      reportDate: reportDate ?? this.reportDate,
      improvements: improvements ?? this.improvements,
      needsImprovement: needsImprovement ?? this.needsImprovement,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
