import 'package:glu_butler/models/report_guide_summary.dart';

/// 리포트 마크다운에서 가이드 섹션 파싱 유틸리티
class ReportParser {
  /// 리포트 마크다운에서 가이드 요약 추출
  ///
  /// 마크다운 구조 기반 파싱 (언어 독립적):
  /// - 3번째 ## 섹션 (index 2) = 가이드 섹션
  /// - 첫 번째 ### = improvements
  /// - 두 번째 ### = needs_improvement
  ///
  /// [markdownContent]: 전체 리포트 마크다운 내용
  /// [reportDate]: 리포트 날짜 (yyyy-MM-dd 형식)
  ///
  /// Returns: ReportGuideSummary 객체, 파싱 실패 시 null
  static ReportGuideSummary? extractGuideSummary(
    String markdownContent,
    String reportDate,
  ) {
    try {
      // 3번째 ## 섹션 찾기 (index 2 = 가이드 섹션)
      final guideSection = _extractSectionByIndex(markdownContent, 2, 2);
      if (guideSection == null) {
        return null;
      }

      // 첫 번째 ### 섹션 (improvements)
      final improvementsText = _extractSubsectionByIndex(guideSection, 0);
      final improvementsList = _parseListItems(improvementsText);

      // 두 번째 ### 섹션 (needs_improvement)
      final needsImprovementText = _extractSubsectionByIndex(guideSection, 1);
      final needsImprovementList = _parseListItems(needsImprovementText);

      // 둘 다 비어있으면 null 반환
      if (improvementsList.isEmpty && needsImprovementList.isEmpty) {
        return null;
      }

      // List<String>을 쉼표로 구분된 문자열로 변환
      final improvements = improvementsList.join(', ');
      final needsImprovement = needsImprovementList.join(', ');

      return ReportGuideSummary(
        reportDate: reportDate,
        improvements: improvements,
        needsImprovement: needsImprovement,
      );
    } catch (e) {
      return null;
    }
  }

  /// N번째 레벨2 헤더(##) 섹션 추출
  ///
  /// [content]: 마크다운 전체 내용
  /// [headerLevel]: 헤더 레벨 (2 for ##)
  /// [index]: 0부터 시작하는 인덱스
  ///
  /// Returns: 섹션 내용, 없으면 null
  static String? _extractSectionByIndex(
    String content,
    int headerLevel,
    int index,
  ) {
    // 모든 레벨2 헤더 찾기 (예: ## 제목)
    final regex = RegExp('^#{$headerLevel} .+\$', multiLine: true);
    final matches = regex.allMatches(content).toList();

    if (index >= matches.length) {
      return null;
    }

    final targetMatch = matches[index];
    final headerEnd = targetMatch.end;

    // 다음 같은 레벨 헤더 찾기
    final nextMatches = regex.allMatches(content, headerEnd);
    final endIndex = nextMatches.isEmpty
        ? content.length
        : nextMatches.first.start;

    // 헤더 다음 줄부터 다음 헤더 전까지
    return content.substring(headerEnd, endIndex).trim();
  }

  /// N번째 레벨3 헤더(###) 서브섹션 추출
  ///
  /// [sectionContent]: 섹션 내용
  /// [index]: 0부터 시작하는 인덱스
  ///
  /// Returns: 서브섹션 내용, 없으면 빈 문자열
  static String _extractSubsectionByIndex(String sectionContent, int index) {
    // 모든 레벨3 헤더 찾기 (예: ### 소제목)
    final regex = RegExp('^### .+\$', multiLine: true);
    final matches = regex.allMatches(sectionContent).toList();

    if (index >= matches.length) {
      return '';
    }

    final targetMatch = matches[index];
    final headerEnd = targetMatch.end;

    // 다음 ### 헤더 찾기
    final endIndex = index + 1 < matches.length
        ? matches[index + 1].start
        : sectionContent.length;

    return sectionContent.substring(headerEnd, endIndex).trim();
  }

  /// 마크다운 리스트 아이템 파싱
  ///
  /// "- 항목1\n- 항목2" 형식의 텍스트에서 항목들을 추출
  static List<String> _parseListItems(String text) {
    if (text.isEmpty) {
      return [];
    }

    final lines = text.split('\n');
    final items = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      // "- ", "* ", "1. " 등으로 시작하는 리스트 항목 추출
      if (trimmed.startsWith('- ') ||
          trimmed.startsWith('* ') ||
          RegExp(r'^\d+\.\s').hasMatch(trimmed)) {
        // 리스트 마커 제거
        final item = trimmed
            .replaceFirst(RegExp(r'^[-*]\s+'), '')
            .replaceFirst(RegExp(r'^\d+\.\s+'), '')
            .trim();

        if (item.isNotEmpty) {
          items.add(item);
        }
      }
    }

    return items;
  }
}
