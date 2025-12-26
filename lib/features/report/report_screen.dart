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
# 혈당 관리 주간 리포트

## 🎯 주요 지표

- **혈당 수치(mg/dL)**: 평균 120, 최저 85, 최고 165
- **목표 범위 내 비율**: 78%
- **변동계수(CV)**: 28.3%
- **혈당 측정 횟수**: 주 24회 (일 평균 3.4회)

&nbsp;

## 📊 현재 당뇨 상태 평가

**진단**: 2형 당뇨 (조절 양호 단계)

평균 혈당 120 mg/dL은 당뇨병 진단 기준(공복 126 mg/dL 이상, 식후 2시간 200 mg/dL 이상)보다 낮은 수준으로 **적극적인 관리가 효과를 보고 있습니다**. 목표 범위 내 비율 78%는 우수한 편이며, 이는 정상 범위로 돌아갈 수 있는 **매우 긍정적인 신호**입니다.

**정상으로 가는 길**: 현재 수치를 유지하고 아래 제시된 개선 사항들을 실천하면, 3-6개월 내 당뇨 전단계 수준으로 개선될 가능성이 높습니다. 특히 체중 감량(5-10%)과 규칙적인 운동은 인슐린 저항성을 근본적으로 개선하여 정상 혈당 수준 회복에 핵심적인 역할을 합니다.

&nbsp;

## 🏃 생활습관 분석

- **수면**: 평균 7시간 30분 (권장 범위) ✓
- **운동**: 주 4회, 평균 35분 (목표 달성)
- **걸음 수**: 일평균 8,500걸음 (우수)
- **식사 시간 규칙성**: 87% (우수)

현재 생활습관은 전반적으로 양호합니다. 이를 꾸준히 유지하는 것만으로도 정상 혈당으로의 회복 가능성이 높아집니다.

&nbsp;

## 💡 상세 분석

**혈당 변동성 - 안정적인 관리 상태**

이번 주 변동계수(CV) 28.3%는 권장 기준(36% 미만)을 충족하는 우수한 수준입니다. 45세 연령대에서 이 정도의 안정성을 보이는 것은 **정상 범위 회복을 위한 훌륭한 기반**이 마련되었음을 의미합니다.

공복 혈당 표준편차 12.4 mg/dL은 매우 안정적입니다. 체중 72kg에서 이러한 안정성은 현재 실천 중인 생활습관이 효과적이라는 증거입니다. 이 패턴을 유지하면서 아래 개선점들을 추가한다면, **정상 혈당 회복이 충분히 가능합니다**.

&nbsp;

**식후 혈당 - 개선 가능한 부분 발견**

점심 식후 2시간 혈당이 평균 158 mg/dL로 측정되었습니다. 정상 범위(140 mg/dL 미만)보다 약간 높지만, **간단한 식습관 조정만으로도 개선 가능한 수준**입니다. 40대는 근육량이 감소하는 시기이지만, 이는 운동으로 충분히 보완할 수 있습니다.**¹**

**실천 가능한 개선 방법**: 점심 식사 시 단백질(닭가슴살, 두부, 생선 등)을 25-30g으로 늘리고, 흰밥 대신 현미밥으로 바꾸면 식후 혈당을 15-20 mg/dL 낮출 수 있습니다. 이렇게 하면 **정상 범위(140 mg/dL 미만)에 도달**할 수 있습니다.

주 2-3회 저항 운동(스쿼트, 팔굽혀펴기 등)을 추가하면 근육량이 증가하여 인슐린 감수성이 20-30% 향상됩니다. 이는 **당뇨를 근본적으로 개선하는 가장 효과적인 방법**입니다.

&nbsp;

**일중 혈당 리듬 - 야간만 주의하면 완벽**

새벽 3-5시 사이 혈당이 평균 92 mg/dL로 **정상 범위**입니다. 새벽 현상도 관찰되지 않아 야간 인슐린 기능이 잘 유지되고 있습니다. 이는 **당뇨가 심각하지 않다는 매우 긍정적인 신호**입니다.

저녁 22시 이후 간식 섭취 시에만 혈당 상승폭이 다소 높게(42 mg/dL) 나타났습니다. 40대 이후에는 야간 인슐린 감수성이 15-20% 낮아지는 것이 자연스러운 현상입니다.**²** 하지만 **저녁 21시 이후 간식만 피하면 이 문제는 완전히 해결**됩니다.

일일 칼로리를 1,800-2,000kcal로 조절하고 야간 간식을 자제하면, 체중 감량과 함께 **정상 혈당 수준에 한 걸음 더 가까워집니다**.

&nbsp;

**운동 효과 - 이미 정상 회복의 길 위에**

운동 후 2-4시간 동안 평균 혈당이 18 mg/dL 감소하는 **탁월한 반응**을 보이고 있습니다. 이는 당신의 몸이 운동에 매우 잘 반응하고 있으며, **인슐린 저항성이 개선되고 있다**는 강력한 증거입니다.

걷기 운동 35분 이상 지속 시 혈당 감소 효과가 뚜렷합니다. 이는 근육의 GLUT4가 활성화되어 인슐린 없이도 포도당을 흡수하기 때문입니다.**³** **현재 운동 습관을 유지만 해도 정상 혈당 회복이 가능합니다**.

&nbsp;

**정상으로 돌아가기 위한 구체적 목표**

- **체중**: 현재 72kg → 목표 65-68kg (3-6개월 내)
  - 주당 0.5-1kg씩 감량 (급격한 감량은 금물)
  - 체중 5-10% 감량 시 혈당 조절이 극적으로 개선됩니다
  - BMI 정상 범위 도달 시 인슐린 필요량이 20-30% 감소

- **HbA1c 목표**: 6개월 내 0.5-0.8% 개선
  - 현재 수준 유지 + 아래 실천 과제 = 정상 범위(5.7% 미만) 도달 가능

- **스트레스 관리**: 하루 10-15분 명상이나 요가
  - 스트레스 호르몬(코르티솔)이 혈당을 올리므로, 이완이 혈당 조절에 직접적 도움

- **정기 검진**: 연 1회 안저·신장 검사로 합병증 예방
  - 조기 발견 시 대부분 회복 가능하므로 검진이 중요합니다

&nbsp;

## 💊 정상 회복을 위한 실천 가이드

**혈당 측정으로 변화 확인하기**

현재 일평균 3.4회 측정도 좋지만, 하루 4-5회로 늘리면 **개선되는 모습을 직접 확인**할 수 있습니다. 변화를 눈으로 보면 동기부여가 되어 실천이 더 쉬워집니다.

- **필수 측정**: 공복(기상 직후), 식후 2시간(주 3회 각 끼니별)
- **추가 권장**: 취침 전, 운동 전후
- **목표**: 주 28-35회로 증량 → 패턴 파악 → 정상 범위 도달 확인

&nbsp;

**정상 회복을 위한 운동 프로그램**

유산소 운동과 저항 운동을 함께 하면 **당뇨를 근본적으로 개선**할 수 있습니다.**⁴** 운동은 약물보다 효과적인 경우가 많으며, 부작용도 없습니다.

**유산소 운동** (주 5회 이상) - 혈당을 즉시 낮춤
- 빠르게 걷기, 자전거, 수영 중 선택
- 1회 30-60분, 중강도 (약간 숨이 찬 정도)
- 식후 1-2시간 내 실시 시 혈당 20-30 mg/dL 감소 효과

**저항 운동** (주 2-3회) - 인슐린 감수성을 장기적으로 개선
- 스쿼트, 팔굽혀펴기, 밴드 운동 등
- 8-10가지 동작, 각 10-15회 반복
- 3개월 후 근육량 증가 → 인슐린 감수성 20-30% 향상

**핵심**: 현재 주 4회 운동 중이므로, 주 5회로 늘리고 저항 운동만 추가하면 됩니다!

&nbsp;

**정상 혈당을 위한 식사 전략**

**식사 구성** (정상 범위로 가는 가장 빠른 길)
- 식사 간격: 4-6시간 (간식 줄이기)
- 탄수화물:단백질:지방 = 50:20:30
- 매 끼니 식이섬유 5-7g (채소, 통곡물) → 혈당 상승 완화

&nbsp;

**공복혈당을 정상으로** (목표: 100 mg/dL 이하)

현재 공복 혈당이 안정적이므로, 아래만 지키면 **정상 범위(100 mg/dL 이하) 도달 가능**:

- 저녁 식사를 취침 3시간 전까지 완료
- 취침 전 간식 자제 (배고프면 견과류 소량)
- 수면 7-8시간 유지 (현재 잘 하고 계십니다!)
- 저녁 과식 지양 (일일 칼로리의 30% 이내)

&nbsp;

**식후혈당을 정상으로** (목표: 140 mg/dL 미만)

현재 158 mg/dL → **목표 140 mg/dL 미만은 충분히 달성 가능**합니다:

- **식사 순서 변경**: 채소 먼저 → 단백질 → 탄수화물 마지막
  - 이것만으로도 식후 혈당 10-15 mg/dL 감소
- **통곡물로 바꾸기**: 흰밥 → 현미밥, 식빵 → 통밀빵
  - 추가로 10-15 mg/dL 감소
- **천천히 먹기**: 20분 이상 씹기 (포만감 증가 + 혈당 완만 상승)
- **식후 걷기**: 15분만 걸어도 혈당 15-20 mg/dL 감소

**결론**: 위 방법들을 실천하면 점심 식후 혈당 158 → 130 mg/dL 달성 가능 (**정상 범위**)

&nbsp;

## 📝 이번 주 실천 과제

**정상으로 돌아가기 위한 5가지 실천** (모두 실천 가능한 간단한 것들입니다!)

- [ ] **점심 식사 개선**: 채소를 1.5배로 늘리고 현미밥으로 바꾸기
  - 효과: 식후 혈당 158 → 140 mg/dL 미만 (정상 범위 도달!)

- [ ] **야간 간식 자제**: 저녁 21시 이후 금식 (배고프면 견과류 한 줌)
  - 효과: 야간 혈당 안정 + 체중 감량 효과

- [ ] **점심 식후 걷기**: 15분만 걸어도 OK (주 5회 이상)
  - 효과: 식후 혈당 즉시 15-20 mg/dL 감소

- [ ] **규칙적인 수면**: 매일 23시±30분 취침 (현재 잘하고 있어요!)
  - 효과: 인슐린 감수성 유지 + 스트레스 감소

- [ ] **혈당 측정 증량**: 하루 4회로 (공복, 점심 식후, 저녁 식후, 취침 전)
  - 효과: 개선되는 모습을 눈으로 확인 → 동기부여 상승

**당신은 이미 잘하고 있습니다!** 위 과제들은 현재 생활에서 조금만 더 노력하면 되는 것들입니다. 3-6개월 후 정상 혈당 수준에 도달한 자신의 모습을 상상해보세요. **충분히 가능합니다!**

&nbsp;

---

## 참고문헌

**¹** Bao J, et al. (2019). Food insulin index: physiologic basis for predicting insulin demand evoked by composite meals. *Diabetes Care*, 42(6), 1159-1161.

**²** Reutrakul S, Van Cauter E. (2018). Sleep influences on obesity, insulin resistance, and risk of type 2 diabetes. *Nature Reviews Endocrinology*, 14(8), 667-684.

**³** Richter EA, Hargreaves M. (2013). Exercise, GLUT4, and skeletal muscle glucose uptake. *Physiological Reviews*, 93(3), 993-1017.

**⁴** Colberg SR, et al. (2016). Physical activity/exercise and diabetes: a position statement of the American Diabetes Association. *Diabetes Care*, 39(11), 2065-2079.

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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor,
          width: 1,
        ),
      ),
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
