import 'package:flutter/material.dart';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/widgets/large_title_scroll_view.dart';

/// 데이터 입력 화면
///
/// 혈당, 식사, 운동 데이터를 입력하기 위한 선택 화면입니다.
/// 탭바 중앙의 + 버튼(FAB)을 눌러 접근합니다.
///
/// ## 입력 유형
/// | 유형 | 아이콘 | 색상 | 라우트 |
/// |------|--------|------|--------|
/// | 혈당 | water_drop | primaryColor | `/input/glucose` |
/// | 식사 | restaurant | secondaryColor | `/input/meal` |
/// | 운동 | directions_run | accentColor | `/input/exercise` |
///
/// ## 주요 기능
/// - 입력 유형 선택 카드
/// - 각 유형별 상세 입력 화면으로 네비게이션
///
/// ## 라우팅
/// - `/input` - 입력 선택 화면 (모달로 표시)
///
/// ## 디자인 상수
/// - [AppTheme.primaryColor] - 혈당 입력 카드
/// - [AppTheme.secondaryColor] - 식사 입력 카드
/// - [AppTheme.accentColor] - 운동 입력 카드
///
/// ## 관련 파일
/// - [MainShell] - FAB 버튼으로 이 화면 호출
/// - [LargeTitleScrollView] - iOS 스타일 스크롤뷰
/// - [AppTheme] - 색상 상수
class InputScreen extends StatelessWidget {
  const InputScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return LargeTitleScrollView(
      title: l10n.add,
      showBackButton: true,
      onRefresh: null,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildInputCard(
                context: context,
                icon: Icons.water_drop,
                title: l10n.enterGlucose,
                subtitle: l10n.bloodGlucose,
                color: AppTheme.primaryColor,
                onTap: () {
                  // TODO: Navigate to glucose input
                },
              ),
              const SizedBox(height: 16),
              _buildInputCard(
                context: context,
                icon: Icons.restaurant,
                title: l10n.enterMeal,
                subtitle: l10n.meal,
                color: AppTheme.secondaryColor,
                onTap: () {
                  // TODO: Navigate to meal input
                },
              ),
              const SizedBox(height: 16),
              _buildInputCard(
                context: context,
                icon: Icons.directions_run,
                title: l10n.enterExercise,
                subtitle: l10n.exercise,
                color: AppTheme.accentColor,
                onTap: () {
                  // TODO: Navigate to exercise input
                },
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildInputCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
