import 'package:flutter/material.dart';
import 'package:glu_butler/core/theme/app_theme.dart';

/// 재사용 가능한 스와이프 카드 컴포넌트
class SwipeableCard extends StatefulWidget {
  /// 카드 내용
  final Widget child;

  /// 스와이프 가능 여부
  final bool swipeable;

  /// 수정 기능 사용 여부
  final bool useEdit;

  /// 삭제 기능 사용 여부
  final bool useRemove;

  /// 삭제 버튼 클릭 시 콜백
  final VoidCallback? onDelete;

  /// 수정 버튼 클릭 시 콜백
  final VoidCallback? onEdit;

  /// 스와이프 시작 시 콜백
  final VoidCallback? onSwipeStart;

  /// 카드 높이 (기본값: null - 자동)
  final double? height;

  /// 바운스 애니메이션 여부 (렌더링 후 자동 실행)
  final bool bounceable;

  const SwipeableCard({
    super.key,
    required this.child,
    this.swipeable = false,
    this.useEdit = false,
    this.useRemove = true,
    this.onDelete,
    this.onEdit,
    this.onSwipeStart,
    this.height,
    this.bounceable = false,
  });

  @override
  State<SwipeableCard> createState() => _SwipeableCardState();
}

// Public interface for closing cards from outside
class SwipeableCardState {
  static void closeAnyOpenCard() {
    _SwipeableCardState._closeAnyOpenCard();
  }
}

class _SwipeableCardState extends State<SwipeableCard>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  double _dragExtent = 0;

  // 전역적으로 열린 카드 추적
  static _SwipeableCardState? _currentlyOpenCard;

  static void _closeAnyOpenCard() {
    _currentlyOpenCard?._closeCard();
  }

  // 최대 드래그 거리 (수정/삭제 기능 여부에 따라 달라짐)
  double get _maxDragDistance =>
      (widget.useEdit && widget.useRemove) ? -160.0 : -100.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    // 바운스 애니메이션 컨트롤러
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _bounceAnimation =
        Tween<double>(
          begin: 0.0,
          end: -25.0, // 왼쪽으로 25px 이동
        ).animate(
          CurvedAnimation(
            parent: _bounceController,
            curve: Curves.easeInOutCubic, // S자 커브
          ),
        );

    // bounceable이 true이면 렌더링 후 바운스 실행
    if (widget.bounceable) {
      _scheduleBounce();
    }
  }

  @override
  void didUpdateWidget(SwipeableCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // bounceable이 false에서 true로 변경되면 바운스 실행
    if (!oldWidget.bounceable && widget.bounceable) {
      _scheduleBounce();
    }
  }

  void _scheduleBounce() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) {
          _bounceController.forward().then((_) {
            _bounceController.reverse();
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    // 스와이프 시작 시 콜백 호출 (처음 한 번만)
    if (_dragExtent == 0 && details.primaryDelta != null && details.primaryDelta! < 0) {
      widget.onSwipeStart?.call();
    }

    // 다른 카드가 열려있으면 닫기
    if (_currentlyOpenCard != null && _currentlyOpenCard != this) {
      _currentlyOpenCard!._closeCard();
    }

    // 애니메이션이 실행 중이면 중단
    if (_controller.isAnimating) {
      _controller.stop();
    }

    setState(() {
      _dragExtent += details.primaryDelta ?? 0;
      _dragExtent = _dragExtent.clamp(_maxDragDistance, 0.0);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    final targetPosition = _dragExtent < _maxDragDistance / 2
        ? _maxDragDistance
        : 0.0;

    // 현재 위치에서 목표 위치까지 애니메이션
    _controller.value = (_dragExtent / _maxDragDistance).abs();

    if (targetPosition == _maxDragDistance) {
      // Open with animation
      _controller.animateTo(1.0, curve: Curves.easeOutCubic).then((_) {
        if (mounted) {
          setState(() {
            _dragExtent = _maxDragDistance;
          });
        }
      });
      _currentlyOpenCard = this;
    } else {
      // Close with animation
      _controller.animateTo(0.0, curve: Curves.easeOutCubic).then((_) {
        if (mounted) {
          setState(() {
            _dragExtent = 0;
          });
          if (_currentlyOpenCard == this) {
            _currentlyOpenCard = null;
          }
        }
      });
    }
  }

  void _closeCard() {
    if (!mounted) return;
    if (_dragExtent < 0) {
      // 현재 위치에서 부드럽게 닫기
      _controller.value = (_dragExtent / _maxDragDistance).abs();
      _controller.animateTo(0.0, curve: Curves.easeOutCubic).then((_) {
        if (mounted) {
          setState(() {
            _dragExtent = 0;
          });
          if (_currentlyOpenCard == this) {
            _currentlyOpenCard = null;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.swipeable) {
      // 스와이프 불가능한 경우: 다른 카드가 열려있으면 닫기
      return GestureDetector(
        onTapDown: (_) {
          if (_currentlyOpenCard != null) {
            _currentlyOpenCard!._closeCard();
          }
        },
        child: widget.child,
      );
    }

    // 스와이프 가능한 경우
    return Stack(
      children: [
        // 1. 가장 아래: 빨간 배경 (useRemove가 true일 때만)
        if (widget.useRemove)
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              height: widget.height,
            ),
          ),
        // 2. 그 위: 파란 배경 (useEdit가 true일 때만, 왼쪽 60 마진)
        if (widget.useEdit)
          Positioned(
            left: 60,
            right: 0,
            top: 0,
            bottom: 0,
            child: Container(
              margin: EdgeInsets.only(
                left: 16,
                right: (widget.useEdit && widget.useRemove) ? 96 : 16,
                top: 5,
                bottom: 5,
              ),
              decoration: BoxDecoration(
                color: AppTheme.iconBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              height: widget.height,
            ),
          ),
        // 3. 그 위: 버튼들
        // 수정/삭제 둘 다 있을 때
        if (widget.useEdit && widget.useRemove) ...[
          // 수정 버튼 (왼쪽)
          Positioned(
            right: 110,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: widget.onEdit,
              ),
            ),
          ),
          // 삭제 버튼 (오른쪽)
          Positioned(
            right: 30,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: widget.onDelete,
              ),
            ),
          ),
        ]
        // 수정만 있을 때
        else if (widget.useEdit)
          Positioned(
            right: 43,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: widget.onEdit,
              ),
            ),
          )
        // 삭제만 있을 때
        else if (widget.useRemove)
          Positioned(
            right: 43,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: widget.onDelete,
              ),
            ),
          ),
        // 4. 가장 위: 스와이프 가능한 카드 (바운스 + 드래그 애니메이션)
        GestureDetector(
          onHorizontalDragUpdate: _handleDragUpdate,
          onHorizontalDragEnd: _handleDragEnd,
          onTapDown: (_) {
            // 다른 카드가 열려있으면 닫기
            if (_currentlyOpenCard != null && _currentlyOpenCard != this) {
              _currentlyOpenCard!._closeCard();
            }
          },
          child: AnimatedBuilder(
            animation: Listenable.merge([_controller, _bounceController]),
            builder: (context, child) {
              // 드래그 오프셋 계산
              final animatedOffset = _controller.value * _maxDragDistance;
              final dragOffset = _controller.isAnimating
                  ? animatedOffset
                  : _dragExtent;

              // 바운스 오프셋 추가 (왼쪽으로)
              final totalOffset = dragOffset + _bounceAnimation.value;

              return Transform.translate(
                offset: Offset(totalOffset, 0),
                child: child,
              );
            },
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
