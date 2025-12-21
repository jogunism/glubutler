import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:glu_butler/core/theme/app_theme.dart';

/// iOS Settings 앱 스타일의 Large Title 스크롤뷰
///
/// Apple의 iOS Settings 앱에서 볼 수 있는 네비게이션 패턴을 구현합니다:
/// - 큰 타이틀(24px)이 컨텐츠와 함께 스크롤
/// - 네비게이션바(44px)는 항상 상단에 고정
/// - 스크롤 시 네비게이션바 타이틀이 페이드인 (10px~30px 구간)
/// - iOS 네이티브 스타일 pull-to-refresh 지원
///
/// ## 스크롤 동작
/// ```
/// offset: 0px   -> 네비게이션바 타이틀 투명도: 0%
/// offset: 10px  -> 네비게이션바 타이틀 투명도: 0% (페이드 시작)
/// offset: 30px  -> 네비게이션바 타이틀 투명도: 100%
/// ```
///
/// ## 사용 예시
/// ```dart
/// LargeTitleScrollView(
///   title: '설정',
///   onRefresh: () async {
///     await fetchData();
///   },
///   slivers: [
///     SliverList(
///       delegate: SliverChildListDelegate([
///         SettingsTile(...),
///       ]),
///     ),
///   ],
/// )
/// ```
///
/// ## 적용된 화면
/// - [FeedScreen] - 피드 탭
/// - [DiaryScreen] - 일기 탭
/// - [ReportScreen] - 리포트 탭
/// - [SettingsScreen] - 설정 탭
///
/// ## 관련 파일
/// - [AppTheme] - iosBackground(), textPrimary() 등
/// - [CupertinoSliverRefreshControl] - iOS 네이티브 리프레시 컨트롤
class LargeTitleScrollView extends StatefulWidget {
  const LargeTitleScrollView({
    super.key,
    required this.title,
    required this.slivers,
    this.onRefresh,
    this.backgroundColor,
    this.showBackButton = false,
    this.showLargeTitle = true,
    this.trailing,
  });

  /// 네비게이션바와 큰 타이틀에 표시될 텍스트
  final String title;

  /// 스크롤 컨텐츠 (SliverList, SliverGrid 등)
  final List<Widget> slivers;

  /// pull-to-refresh 콜백
  ///
  /// null이면 refresh 기능이 비활성화됩니다.
  /// 예: 설정 화면은 새로고침이 불필요하므로 null 전달
  final Future<void> Function()? onRefresh;

  /// 배경색 (null이면 [AppTheme.iosBackground] 사용)
  final Color? backgroundColor;

  /// 뒤로가기 버튼 표시 여부
  ///
  /// true면 네비게이션바 왼쪽에 iOS 스타일 뒤로가기 버튼이 표시됩니다.
  /// push로 진입하는 화면에서 사용합니다.
  final bool showBackButton;

  /// 큰 타이틀 표시 여부
  ///
  /// false면 컨텐츠 영역의 큰 타이틀이 숨겨지고, 네비게이션바 타이틀만 표시됩니다.
  /// 컨텐츠 자체에 타이틀이 있는 화면에서 사용합니다.
  final bool showLargeTitle;

  /// 네비게이션바 우측에 표시될 위젯 (예: 설정 아이콘)
  final Widget? trailing;

  @override
  State<LargeTitleScrollView> createState() => _LargeTitleScrollViewState();
}

class _LargeTitleScrollViewState extends State<LargeTitleScrollView> {
  double _navTitleOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    // 큰 타이틀이 없으면 네비게이션바 타이틀을 항상 표시
    if (!widget.showLargeTitle) {
      _navTitleOpacity = 1.0;
    }
  }

  void _onScroll(double offset) {
    // 큰 타이틀이 없으면 스크롤에 따른 opacity 변경 불필요
    if (!widget.showLargeTitle) return;

    // 스크롤 위치에 따라 네비게이션바 타이틀 투명도 계산
    // 10px부터 페이드 시작, 30px에서 완전히 표시
    double opacity = 0.0;
    if (offset > 10) {
      opacity = ((offset - 10) / 20).clamp(0.0, 1.0);
    }
    if (opacity != _navTitleOpacity) {
      setState(() {
        _navTitleOpacity = opacity;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final backgroundColor =
        widget.backgroundColor ?? AppTheme.iosBackground(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // 메인 스크롤 컨텐츠
          _buildScrollContent(context, topPadding, backgroundColor),

          // 네비게이션바 - 항상 표시, 타이틀만 페이드인/아웃
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(top: topPadding),
              color: backgroundColor,
              child: SizedBox(
                height: 44,
                child: Stack(
                  children: [
                    // 뒤로가기 버튼
                    if (widget.showBackButton)
                      Positioned(
                        left: 8,
                        top: 0,
                        bottom: 0,
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.pop(context),
                          child: const Icon(
                            CupertinoIcons.back,
                            color: AppTheme.primaryColor,
                            size: 28,
                          ),
                        ),
                      ),
                    // 타이틀
                    Center(
                      child: Opacity(
                        opacity: _navTitleOpacity,
                        child: Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary(context),
                          ),
                        ),
                      ),
                    ),
                    // 우측 trailing 위젯
                    if (widget.trailing != null)
                      Positioned(
                        right: 8,
                        top: 0,
                        bottom: 0,
                        child: Center(child: widget.trailing!),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollContent(
    BuildContext context,
    double topPadding,
    Color backgroundColor,
  ) {
    final navBarHeight = topPadding + 44;

    return Padding(
      padding: EdgeInsets.only(top: navBarHeight),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification) {
            _onScroll(notification.metrics.pixels);
          }
          return false;
        },
        child: CustomScrollView(
          // primary: true enables Status Bar tap to scroll to top
          primary: true,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // iOS 기본 스타일 pull-to-refresh
            if (widget.onRefresh != null)
              CupertinoSliverRefreshControl(
                onRefresh: widget.onRefresh,
              ),
            // 큰 타이틀 (옵션)
            if (widget.showLargeTitle)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 8,
                    left: 16,
                    right: 16,
                    bottom: 8,
                  ),
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                ),
              ),
            // 사용자 정의 slivers
            ...widget.slivers,
          ],
        ),
      ),
    );
  }
}
