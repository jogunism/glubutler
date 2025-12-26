import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/widgets/large_title_scroll_view.dart';
import 'package:glu_butler/core/widgets/settings_icon_button.dart';
import 'package:glu_butler/core/widgets/modals/report_guide_modal.dart';

/// 리포트 화면
///
/// 혈당 데이터의 통계 및 분석 리포트를 표시하는 화면입니다.
/// [LargeTitleScrollView]를 사용하여 iOS 스타일 네비게이션을 구현합니다.
///
/// ## 주요 기능
/// - 일간/주간 혈당 통계
/// - 평균 혈당, 변동성 분석
/// - AI 인사이트 (Pro 기능)
/// - 혈당 점수 표시
/// - Pull-to-refresh로 데이터 새로고침
///
/// ## 라우팅
/// - `/report` - 탭바 인덱스 2
///
/// ## Pro 기능
/// - 고급 분석 및 리포트
/// - AI 기반 인사이트
/// - 데이터 내보내기
///
/// ## 관련 파일
/// - [LargeTitleScrollView] - iOS 스타일 스크롤뷰
/// - [MainShell] - 탭바 네비게이션
/// - [SettingsService] - Pro 구독 상태 확인
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String? _reportContent; // 레포트 마크다운 내용
  DateTime? _reportStartDate;
  DateTime? _reportEndDate;

  Future<void> _generateReport() async {
    // 안내 모달 표시
    final confirmed = await ReportGuideModal.show(context);

    if (!confirmed) return;

    // TODO: API 호출 및 DB 저장
    // 목업 데이터로 대체
    setState(() {
      _reportStartDate = DateTime.now().subtract(const Duration(days: 6));
      _reportEndDate = DateTime.now();
      _reportContent = '''
# 혈당 관리 리포트

## 📋 주요 지표

| 항목 | 수치 | 평가 |
|------|------|------|
| 평균 혈당 | **120** mg/dL | 양호 |
| 최저/최고 | **85** / **165** mg/dL | - |
| 목표 범위 내 비율 | **78**% | 우수 |
| 변동계수(CV) | **28.3**% | 양호 |
| 공복 혈당 | **98** mg/dL | 정상 |
| 식후 2시간 혈당 | **158** mg/dL | 개선 필요 |

&nbsp;

### 누락 데이터 안내
다음 정보가 있으면 더 정확한 분석이 가능합니다:
- **생리 주기** (여성): 호르몬 변화가 혈당에 영향을 줄 수 있습니다
- **음주 기록**: 알코올 섭취는 혈당 변동에 영향을 줍니다
- **질병/컨디션**: 감기, 염증 등은 혈당을 상승시킬 수 있습니다

&nbsp;

## 📊 혈당평가

### 지난주 대비 개선 사항
- **평균 혈당**: 125 → 120 mg/dL (5 mg/dL 개선) ✓
- **목표 범위 내 비율**: 72% → 78% (6%p 증가) ✓
- **운동 빈도**: 주 3회 → 주 4회 (1회 증가) ✓
- **야간 간식**: 주 5회 → 주 3회 (2회 감소) ✓

지난주 리포트에서 권장했던 운동 증량과 야간 간식 줄이기를 성공적으로 실천하셨습니다. **매우 잘하고 계십니다!**

&nbsp;

### 혈당 지표 분석

**평균 혈당 120 mg/dL - 양호한 관리 상태**

현재 평균 혈당은 당뇨병 진단 기준(공복 126 mg/dL 이상)보다 낮은 수준입니다. 목표 범위 내 비율 78%는 우수한 편이며, 지속적인 관리로 정상 범위에 근접하고 있습니다.

**공복 혈당 98 mg/dL - 정상 범위**

공복 혈당이 정상 범위(70-100 mg/dL) 내에 있습니다. 이는 야간 인슐린 기능이 잘 유지되고 있다는 긍정적인 신호입니다.

**식후 혈당 158 mg/dL - 개선 필요**

점심 식후 2시간 혈당이 평균 158 mg/dL로 정상 범위(140 mg/dL 미만)보다 약간 높습니다. 하지만 간단한 식습관 조정으로 충분히 개선 가능한 수준입니다. 식사 순서를 변경하거나(채소 먼저 → 단백질 → 탄수화물) 흰밥을 현미밥으로 바꾸면 10-20 mg/dL 감소 효과를 기대할 수 있습니다.**¹**

&nbsp;

### 상세 분석

**신체 정보 (남성, 45세, 72kg, BMI 24.2, 2형 당뇨)**

45세 남성으로 체중 72kg, BMI 24.2는 정상 범위에 가깝습니다. 2형 당뇨 진단 후 3년 2개월이 경과했으며, 현재 혈당 지표들이 양호한 것으로 보아 적극적인 관리가 효과를 보고 있습니다.

**수면 (평균 7시간 30분, 규칙성 85%)**

수면 시간과 질이 모두 양호합니다. 충분한 수면은 인슐린 감수성을 유지하고 스트레스 호르몬(코르티솔)을 조절하여 혈당 관리에 도움이 됩니다.**²** 현재 취침 시간 규칙성 85%는 우수한 수준입니다.

**운동 (주 4회, 일평균 8,500걸음)**

주 4회 유산소 운동(걷기)과 일평균 8,500걸음은 매우 우수합니다. 운동 후 평균 혈당이 18 mg/dL 감소하는 것으로 보아 운동 효과가 뚜렷합니다. 다만 저항 운동이 없는 점은 아쉽습니다. 유산소와 저항 운동을 병행하면 인슐린 감수성이 20-30% 더 향상될 수 있습니다.**³** 45세 연령대는 근육량이 감소하는 시기이므로 주 2-3회 저항 운동(스쿼트, 팔굽혀펴기 등) 추가를 권장합니다.

**식습관 (규칙성 87%, 야간 간식 주 3회)**

식사 시간 규칙성 87%는 매우 우수합니다. 규칙적인 식사는 혈당 안정에 중요한 역할을 합니다. 다만 야간 간식(주 3회)이 혈당 상승에 영향을 주고 있습니다. 저녁 22시 이후 간식 섭취 시 혈당 상승폭이 42 mg/dL로 높게 나타났습니다. 40대 이후 야간 인슐린 감수성이 15-20% 낮아지므로 저녁 21시 이후 간식을 자제하면 개선될 것입니다.**²** 수분 섭취는 일평균 1.6L로 최소 권장량을 충족하나, 2L 이상으로 늘리면 더 좋습니다.**⁴**

**스트레스 (중간 수준, 업무 스트레스 주 3-4회)**

일기 분석 결과 업무 스트레스가 주 3-4회 언급되었습니다. 스트레스 호르몬은 혈당을 상승시키므로, 하루 10-15분 명상이나 요가 같은 이완 활동을 추천합니다.

**약물 복용 (메트포민 500mg, 복용 규칙성 95%)**

메트포민 복용 규칙성 95%는 매우 우수합니다. 이는 혈당 관리의 중요한 기반이 되며, 이 상태를 계속 유지하시면 좋겠습니다.

**혈당 측정 (일평균 3.4회, 규칙성 82%)**

주 24회 측정(일평균 3.4회)은 패턴 파악에 충분하나, 하루 4-5회로 늘리면 더 정확한 분석이 가능합니다. 공복 7회, 식후 14회는 양호하나 취침 전 측정이 주 3회로 부족합니다. 취침 전 혈당은 야간 저혈당 예방에 중요하므로 주 7회로 증량을 권장합니다.

&nbsp;

## 📝 가이드

### 지난 리포트 대비 개선 현황

**✓ 평균 혈당 5 mg/dL 감소 (125 → 120 mg/dL)**
- 지난주 권장했던 운동 증량과 야간 간식 줄이기를 성공적으로 실천한 결과입니다
- 이 추세를 유지하면 3개월 내 평균 혈당 115 mg/dL 이하 달성 가능합니다

**✓ 목표 범위 내 비율 6%p 증가 (72% → 78%)**
- 혈당 조절이 더 안정적으로 이루어지고 있습니다
- 목표는 85% 이상이며, 식후 혈당 관리를 개선하면 충분히 도달 가능합니다

**✓ 운동 빈도 증가 (주 3회 → 주 4회)**
- 운동 후 평균 혈당이 18 mg/dL 감소하는 탁월한 효과를 보이고 있습니다
- 꾸준히 유지하면서 저항 운동을 추가하면 더 큰 효과를 기대할 수 있습니다

**✓ 야간 간식 감소 (주 5회 → 주 3회)**
- 야간 혈당 관리가 개선되고 있습니다
- 주 1회 이하로 줄이면 공복 혈당이 더욱 안정될 것입니다

&nbsp;

### 개선이 필요한 부분

**1. 식후 혈당 관리 (우선순위: 높음)**
- **현재**: 식후 2시간 혈당 158 mg/dL
- **목표**: 140 mg/dL 미만
- **개선 방법**:
  - 식사 순서 변경 (채소 먼저 → 단백질 → 탄수화물)
  - 흰밥을 현미밥으로 교체
  - 식후 15분 걷기
- **다음 리포트에서 확인할 사항**: 식후 혈당 수치 변화

**2. 저항 운동 추가 (우선순위: 높음)**
- **현재**: 저항 운동 주 0회
- **목표**: 주 2-3회
- **개선 방법**:
  - 스쿼트, 팔굽혀펴기 등 간단한 동작부터 시작
  - 1회 15-20분, 8-10가지 동작
- **기대 효과**: 인슐린 감수성 20-30% 향상
- **다음 리포트에서 확인할 사항**: 저항 운동 실천 빈도 및 평균 혈당 변화

**3. 야간 간식 자제 (우선순위: 중간)**
- **현재**: 주 3회 야간 간식 (지난주 5회에서 개선됨)
- **목표**: 주 0-1회
- **개선 방법**:
  - 저녁 21시 이후 금식
  - 배고프면 견과류 소량 또는 물
- **다음 리포트에서 확인할 사항**: 야간 간식 빈도 및 야간 혈당 안정성

**4. 수분 섭취 증량 (우선순위: 낮음)**
- **현재**: 일평균 1.6L
- **목표**: 2L 이상
- **개선 방법**: 매 식사 시 물 한 잔 추가
- **다음 리포트에서 확인할 사항**: 수분 섭취량

**5. 스트레스 관리 (우선순위: 중간)**
- **현재**: 업무 스트레스 주 3-4회 언급
- **목표**: 스트레스 관리 루틴 확립
- **개선 방법**: 하루 10-15분 명상, 요가, 심호흡
- **다음 리포트에서 확인할 사항**: 스트레스 수준 변화 및 혈당 영향

**6. 혈당 측정 패턴 개선 (우선순위: 낮음)**
- **현재**: 취침 전 측정 주 3회
- **목표**: 취침 전 측정 주 7회
- **개선 방법**: 취침 전 측정을 습관화
- **다음 리포트에서 확인할 사항**: 측정 빈도 및 야간 저혈당 여부

&nbsp;

---

## 참고문헌

**¹** Bao J, et al. (2019). Food insulin index: physiologic basis for predicting insulin demand evoked by composite meals. *Diabetes Care*, 42(6), 1159-1161.

**²** Reutrakul S, Van Cauter E. (2018). Sleep influences on obesity, insulin resistance, and risk of type 2 diabetes. *Nature Reviews Endocrinology*, 14(8), 667-684.

**³** Richter EA, Hargreaves M. (2013). Exercise, GLUT4, and skeletal muscle glucose uptake. *Physiological Reviews*, 93(3), 993-1017.

**⁴** Johnson EC, et al. (2016). Water intake and hydration biomarkers in adults. *European Journal of Nutrition*, 55(2), 25-41.

&nbsp;

*이 리포트는 정상 혈당 회복을 위한 AI 분석 자료이며, 전문의의 진료를 대체하지 않습니다. 구체적인 치료 계획은 담당 의사와 상담하시기 바랍니다.*
''';
    });
  }

  void _viewPastReports() {
    // TODO: 지난 리포트 목록 화면으로 이동
    debugPrint('[ReportScreen] View past reports');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return LargeTitleScrollView(
      title: l10n.report,
      trailing: const SettingsIconButton(),
      slivers: [
        if (_reportContent == null)
          // 레포트 없을 때: 빈 화면 + 생성 버튼
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.leaderboard,
                      size: 80,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.report,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.noReportYet,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 32),
                    // 레포트 생성 버튼
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                      onPressed: _generateReport,
                      child: Text(
                        l10n.generateReport,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          // 레포트 있을 때: 기간 + 지난 리포트 버튼 + 내용
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 기간 + 지난 리포트 보기 버튼
                _buildReportHeader(l10n, theme),
                const SizedBox(height: 16),
                // 레포트 내용 (마크다운)
                _buildReportContent(theme),
              ]),
            ),
          ),
      ],
    );
  }

  Widget _buildReportHeader(AppLocalizations l10n, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 기간 표시
          Text(
            _formatPeriod(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          // 지난 리포트 보기 버튼
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minSize: 0,
            onPressed: _viewPastReports,
            child: Text(
              l10n.viewPastReports,
              style: TextStyle(
                color: theme.primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent(ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border.all(
          color: theme.dividerColor,
          width: 1,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.all(3),
        padding: const EdgeInsets.all(3),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: theme.dividerColor.withOpacity(0.4),
            strokeWidth: 1,
            dashWidth: 4,
            dashSpace: 3,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: MarkdownBody(
              data: _reportContent ?? '',
              softLineBreak: true,
              styleSheet: MarkdownStyleSheet(
                h1: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
                h2: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                h3: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
                p: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  fontSize: 15,
                ),
                listBullet: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  fontSize: 15,
                ),
                strong: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                em: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  fontSize: 15,
                ),
                a: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
                blockSpacing: 12,
                listIndent: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatPeriod() {
    if (_reportStartDate == null || _reportEndDate == null) {
      return '';
    }

    final start = _reportStartDate!;
    final end = _reportEndDate!;

    // 같은 날이면 단일 날짜로 표시
    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return '${start.year}년 ${start.month}월 ${start.day}일';
    }

    // 같은 월이면 월은 한번만 표시
    if (start.year == end.year && start.month == end.month) {
      return '${start.month}월 ${start.day}일 ~ ${end.day}일';
    }

    // 다른 월이면 둘 다 표시
    return '${start.month}월 ${start.day}일 ~ ${end.month}월 ${end.day}일';
  }
}

/// 점선 테두리를 그리는 CustomPainter
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path();

    // Top border
    double startX = 0;
    while (startX < size.width) {
      path.moveTo(startX, 0);
      path.lineTo(startX + dashWidth, 0);
      startX += dashWidth + dashSpace;
    }

    // Right border
    double startY = 0;
    while (startY < size.height) {
      path.moveTo(size.width, startY);
      path.lineTo(size.width, startY + dashWidth);
      startY += dashWidth + dashSpace;
    }

    // Bottom border
    startX = size.width;
    while (startX > 0) {
      path.moveTo(startX, size.height);
      path.lineTo(startX - dashWidth, size.height);
      startX -= dashWidth + dashSpace;
    }

    // Left border
    startY = size.height;
    while (startY > 0) {
      path.moveTo(0, startY);
      path.lineTo(0, startY - dashWidth);
      startY -= dashWidth + dashSpace;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
