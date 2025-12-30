import 'dart:math' as math;

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
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late AnimationController _waveController;
  double _currentProgress = 0.0;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    // 전체 랜덤 duration (5초~12초) - 한번만 설정
    final totalDuration = 5000 + _random.nextInt(7000);

    _controller = AnimationController(
      duration: Duration(milliseconds: totalDuration),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: widget.progress)
        .animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.forward();

    // 물결 애니메이션 (무한 반복)
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
  }

  @override
  void didUpdateWidget(WaterDropLoading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _currentProgress = _animation.value;

      // 100%로 완료되는 경우 빠르게 (500ms)
      final isCompleting = widget.progress >= 1.0;

      int newDuration;
      if (isCompleting) {
        newDuration = 500;
      } else {
        // 일정한 속도로 차오르도록 고정 duration (2초)
        newDuration = 2000;
      }

      _controller.duration = Duration(milliseconds: newDuration);
      _animation = Tween<double>(
        begin: _currentProgress,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: isCompleting ? Curves.easeOut : Curves.linear,
      ));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_animation, _waveController]),
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
              // 빨간색으로 차오르는 부분 (아래에서 위로, 물결 효과)
              Align(
                alignment: Alignment.bottomCenter,
                child: ClipPath(
                  clipper: _WaveClipper(
                    progress: validProgress,
                    wavePhase: _waveController.value,
                  ),
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

/// 물결 효과를 위한 CustomClipper
///
/// 물방울 아이콘을 아래에서 위로 채우되, 윗부분에 물결 효과를 추가합니다.
class _WaveClipper extends CustomClipper<Path> {
  final double progress;
  final double wavePhase;

  _WaveClipper({
    required this.progress,
    required this.wavePhase,
  });

  @override
  Path getClip(Size size) {
    final path = Path();

    // 진행률에 따른 높이 계산
    final waterLevel = size.height * (1 - progress);

    // 물결 효과 파라미터
    final waveAmplitude = size.width * 0.02; // 물결 높이
    final waveFrequency = 2.0; // 물결 개수

    // 왼쪽 아래에서 시작
    path.moveTo(0, size.height);

    // 왼쪽 면을 따라 물 높이까지 올라감
    path.lineTo(0, waterLevel);

    // 물결 효과 (사인 곡선)
    for (double x = 0; x <= size.width; x += 1) {
      final normalizedX = x / size.width;
      final wave = waveAmplitude *
        math.sin((normalizedX * waveFrequency + wavePhase) * 2 * math.pi);
      path.lineTo(x, waterLevel + wave);
    }

    // 오른쪽 면을 따라 아래로
    path.lineTo(size.width, size.height);

    // 닫기
    path.close();

    return path;
  }

  @override
  bool shouldReclip(_WaveClipper oldClipper) {
    return oldClipper.progress != progress || oldClipper.wavePhase != wavePhase;
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
