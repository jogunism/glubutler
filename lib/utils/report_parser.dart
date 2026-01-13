import 'package:glu_butler/models/report_guide_summary.dart';

/// 리포트 마크다운에서 가이드 섹션 파싱 유틸리티
class ReportParser {
  /// 리포트 마크다운에서 가이드 요약 추출
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
      // "## 📝 가이드" 섹션 찾기
      final guideSection = _extractSection(markdownContent, '## 📝 가이드');
      if (guideSection == null) {
        return null;
      }

      // "### 잘하고 계신점" 섹션 추출
      final improvementsText =
          _extractSubsection(guideSection, '### 잘하고 계신점');
      final improvements = _parseListItems(improvementsText);

      // "### 개선이 필요한 부분" 섹션 추출
      final needsImprovementText =
          _extractSubsection(guideSection, '### 개선이 필요한 부분');
      final needsImprovement = _parseListItems(needsImprovementText);

      // 둘 다 비어있으면 null 반환
      if (improvements.isEmpty && needsImprovement.isEmpty) {
        return null;
      }

      return ReportGuideSummary(
        reportDate: reportDate,
        improvements: improvements,
        needsImprovement: needsImprovement,
      );
    } catch (e) {
      return null;
    }
  }

  /// 특정 헤더로 시작하는 섹션 추출
  ///
  /// 해당 헤더부터 다음 같은 레벨 헤더 전까지의 내용을 반환
  static String? _extractSection(String content, String header) {
    final headerIndex = content.indexOf(header);
    if (headerIndex == -1) {
      return null;
    }

    // 헤더의 레벨 확인 (예: "## " = level 2)
    final headerLevel = header.split(' ').first.length;

    // 다음 같은 레벨 헤더 찾기
    final regex = RegExp('^#{$headerLevel} ', multiLine: true);
    final matches = regex.allMatches(content, headerIndex + header.length);

    final endIndex = matches.isEmpty
        ? content.length
        : matches.first.start;

    return content.substring(headerIndex + header.length, endIndex).trim();
  }

  /// 서브섹션 추출
  ///
  /// 특정 서브헤더부터 다음 서브헤더 전까지의 내용을 반환
  static String _extractSubsection(String sectionContent, String subheader) {
    final subheaderIndex = sectionContent.indexOf(subheader);
    if (subheaderIndex == -1) {
      return '';
    }

    // 다음 ### 헤더 찾기
    final nextSubheaderIndex =
        sectionContent.indexOf('###', subheaderIndex + subheader.length);

    final endIndex = nextSubheaderIndex == -1
        ? sectionContent.length
        : nextSubheaderIndex;

    return sectionContent
        .substring(subheaderIndex + subheader.length, endIndex)
        .trim();
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
