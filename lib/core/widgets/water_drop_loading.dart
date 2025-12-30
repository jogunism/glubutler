import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:glu_butler/core/theme/app_theme.dart';

/// 물방울 모양의 로딩 인디케이터
///
/// 아래에서 위로 차오르는 애니메이션 효과를 제공합니다.
/// 리포트 생성 등 긴 작업의 진행률을 시각적으로 표현합니다.
class WaterDropLoading extends StatefulWidget {
  /// 진행률 (0.0 ~ 1.0)
  final double progress;

  /// 물방울 크기
  final double size;

  /// 물방울 색상
  final Color color;

  const WaterDropLoading({
    super.key,
    required this.progress,
    this.size = 120,
    this.color = AppTheme.iconRed,
  });

  @override
  State<WaterDropLoading> createState() => _WaterDropLoadingState();
}

class _WaterDropLoadingState extends State<WaterDropLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _currentProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 5000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: widget.progress)
        .animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(WaterDropLoading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _currentProgress = _animation.value;
      _animation = Tween<double>(
        begin: _currentProgress,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final validProgress = _animation.value.clamp(0.0, 1.0);

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 회색 배경 아이콘 (전체)
              Icon(
                CupertinoIcons.drop_fill,
                size: widget.size,
                color: Colors.grey.withValues(alpha: 0.3),
              ),
              // 빨간색으로 차오르는 부분 (아래에서 위로)
              Align(
                alignment: Alignment.bottomCenter,
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    heightFactor: validProgress,
                    child: SizedBox(
                      width: widget.size,
                      height: widget.size,
                      child: Icon(
                        CupertinoIcons.drop_fill,
                        size: widget.size,
                        color: widget.color,
                      ),
                    ),
                  ),
                ),
              ),
              // 진행률 텍스트
              Text(
                '${(validProgress * 100).toInt()}%',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: widget.size * 0.2,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 전체 화면 로딩 오버레이
///
/// 화면을 dimmed 처리하고 중앙에 물방울 로딩 애니메이션을 표시합니다.
class WaterDropLoadingOverlay extends StatelessWidget {
  /// 진행률 (0.0 ~ 1.0)
  final double progress;

  /// 로딩 메시지
  final String? message;

  const WaterDropLoadingOverlay({
    super.key,
    required this.progress,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            WaterDropLoading(
              progress: progress,
              size: 120,
            ),
            if (message != null) ...[
              const SizedBox(height: 24),
              Text(
                message!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 다이얼로그로 표시
  static void show(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) => WaterDropLoadingOverlay(
        progress: 0.0,
        message: message,
      ),
    );
  }

  /// 다이얼로그 닫기
  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}
